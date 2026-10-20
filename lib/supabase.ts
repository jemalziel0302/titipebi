
import { cookies } from 'next/headers';

export function config() {
  return {
    url: process.env.NEXT_PUBLIC_SUPABASE_URL?.trim(),
    key: process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY?.trim()
  };
}

export function configured() {
  const { url, key } = config();
  return Boolean(url && key);
}

export async function sb<T = Record<string, unknown>>(
  path: string,
  init: RequestInit = {},
  token?: string
): Promise<T> {
  const { url, key } = config();

  if (!url || !key) {
    throw new Error('Supabase belum dikonfigurasi.');
  }

  let endpoint: URL;

  try {
    const base = new URL(url);

    if (
      base.protocol !== 'https:' ||
      !base.hostname.endsWith('.supabase.co') ||
      base.pathname !== '/'
    ) {
      throw new Error('INVALID_BASE_URL');
    }

    endpoint = new URL(path, base);
  } catch {
    throw new Error(
      'NEXT_PUBLIC_SUPABASE_URL tidak valid. ' +
      'Gunakan Project URL seperti https://xxxxx.supabase.co ' +
      'tanpa /rest/v1.'
    );
  }

  const response = await fetch(endpoint.toString(), {
    ...init,
    cache: 'no-store',
    headers: {
      apikey: key,
      Authorization: `Bearer ${token || key}`,
      'Content-Type': 'application/json',
      ...init.headers
    }
  });

  if (!response.ok) {
    const error = await response.json().catch(() => ({})) as {
      message?: string;
      msg?: string;
      error_description?: string;
      error?: string;
    };

    throw new Error(
      error.message ||
      error.msg ||
      error.error_description ||
      error.error ||
      `Supabase request failed (${response.status})`
    );
  }

  return (
    response.status === 204
      ? null
      : await response.json()
  ) as T;
}

export async function requireAdmin() {
  const token = (await cookies()).get('te-session')?.value;

  if (!token) {
    throw new Error('UNAUTHORIZED');
  }

  const user = await sb<{ id: string }>(
    '/auth/v1/user',
    {},
    token
  );

  const roles = await sb<{ user_id: string }[]>(
    `/rest/v1/admin_users?user_id=eq.${encodeURIComponent(user.id)}&select=user_id`,
    {},
    token
  );

  if (!roles.length) {
    throw new Error('UNAUTHORIZED');
  }

  return token;
}

export function sameOrigin(req: Request) {
  const origin = req.headers.get('origin');

  return !origin || origin === new URL(req.url).origin;
}
