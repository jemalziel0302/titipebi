import type {Metadata} from 'next';
import './globals.css';
import Store from '@/components/store';
export const metadata:Metadata={title:'titipebi — Titip barang impianmu',description:'Pilihan tas, sepatu, fashion, dan aksesoris dari China. Temukan favoritmu dan konsultasikan pre-order bersama titipebi.',icons:{icon:'/favicon.svg'}};
export default function RootLayout({children}:{children:React.ReactNode}){return <html lang="id"><body><Store/>{children}</body></html>;}
