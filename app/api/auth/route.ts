
import { NextResponse } from 'next/server';
import { cookies } from 'next/headers';
import {
  configured,
  sb,
  requireAdmin,
  sameOrigin
} from '@/lib/supabase';
import { z } from 'zod';

export async function GET() {
  try {
    await requireAdmin();

    return NextResponse.json({
      authenticated: true
    });
  } catch {
    return NextResponse.json(
      {
        authenticated: false,
        configured: configured()
      },
      { status: 401 }
    );
  }
}

export async function POST(req: Request) {
  if (!sameOrigin(req)) {
    return NextResponse.json(
      { error: 'Origin tidak valid' },
      { status: 403 }
    );
  }

  if (!configured()) {
    return NextResponse.json(
      { error: 'Supabase belum dikonfigurasi.' },
      { status: 503 }
    );
  }

  let body: { email: string; password: string };

  try {
    body = z.object({
      email: z.string().email(),
      password: z.string().min(1).max(200)
    }).parse(await req.json());
  } catch {
    return NextResponse.json(
      { error: 'Format email atau password tidak valid.' },
      { status: 400 }
    );
  }

  try {
    const session = await sb<{
      user: { id: string };
      access_token: string;
      expires_in: number;
    }>(
      '/auth/v1/token?grant_type=password',
      {
        method: 'POST',
        body: JSON.stringify(body)
      }
    );

    let roles: { user_id: string }[];

    try {
      roles = await sb<{ user_id: string }[]>(
        `/rest/v1/admin_users?user_id=eq.${encodeURIComponent(session.user.id)}&select=user_id`,
        {},
        session.access_token
      );
    } catch (error) {
      console.error(
        '[AUTH] Pemeriksaan role admin gagal:',
        error instanceof Error ? error.message : 'Unknown error'
      );

      return NextResponse.json(
        { error: 'Pemeriksaan akses admin gagal di server.' },
        { status: 502 }
      );
    }

    if (!roles.length) {
      return NextResponse.json(
        { error: 'Akun tidak memiliki akses admin.' },
        { status: 403 }
      );
    }

    (await cookies()).set(
      'te-session',
      session.access_token,
      {
        httpOnly: true,
        secure: process.env.NODE_ENV === 'production',
        sameSite: 'strict',
        path: '/',
        maxAge: session.expires_in
      }
    );

    return NextResponse.json({ ok: true });

  } catch (error) {
    console.error(
      '[AUTH] Login Supabase gagal:',
      error instanceof Error ? error.message : 'Unknown error'
    );

    return NextResponse.json(
      {
        error: 'Autentikasi Supabase gagal. Periksa log terminal server.'
      },
      { status: 401 }
    );
  }
}

export async function DELETE(req: Request) {
  if (!sameOrigin(req)) {
    return NextResponse.json(
      { error: 'Origin tidak valid' },
      { status: 403 }
    );
  }

  const jar = await cookies();
  const token = jar.get('te-session')?.value;

  if (token) {
    await sb(
      '/auth/v1/logout',
      { method: 'POST' },
      token
    ).catch(() => {});
  }

  jar.delete('te-session');

  return NextResponse.json({ ok: true });
}
