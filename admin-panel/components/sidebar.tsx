'use client';
import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { useAuth } from '@/lib/auth';
import {
    LayoutDashboard, Users, Home, Clock, MessageSquare,
    CreditCard, Settings, LogOut, Building2, ChevronRight
} from 'lucide-react';
import clsx from 'clsx';

const nav = [
    { href: '/dashboard', icon: LayoutDashboard, label: 'Dashboard' },
    { href: '/users', icon: Users, label: 'Kullanıcılar' },
    { href: '/listings', icon: Home, label: 'İlanlar' },
    { href: '/listings/pending', icon: Clock, label: 'Bekleyen İlanlar' },
    { href: '/messages', icon: MessageSquare, label: 'Mesajlar' },
    { href: '/payments', icon: CreditCard, label: 'Ödemeler' },
    { href: '/settings', icon: Settings, label: 'Ayarlar' },
];

export default function Sidebar() {
    const pathname = usePathname();
    const { user, logout } = useAuth();
    const router = useRouter();

    return (
        <aside className="fixed left-0 top-0 h-screen w-64 bg-slate-900 border-r border-slate-800 flex flex-col z-50">
            {/* Logo */}
            <div className="px-6 py-5 border-b border-slate-800">
                <div className="flex items-center gap-3">
                    <div className="w-9 h-9 rounded-xl bg-gradient-to-br from-violet-600 to-indigo-600 flex items-center justify-center">
                        <Building2 size={18} className="text-white" />
                    </div>
                    <div>
                        <p className="text-sm font-bold text-white">EsaEmlak</p>
                        <p className="text-[10px] text-violet-400 font-medium tracking-widest uppercase">Admin Panel</p>
                    </div>
                </div>
            </div>

            {/* Nav */}
            <nav className="flex-1 px-3 py-4 space-y-0.5 overflow-y-auto">
                {nav.map(({ href, icon: Icon, label }) => {
                    const active = pathname === href || (href !== '/dashboard' && pathname.startsWith(href));
                    return (
                        <Link
                            key={href}
                            href={href}
                            className={clsx(
                                'flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-medium transition-all group',
                                active
                                    ? 'bg-violet-600/20 text-violet-300 border border-violet-600/30'
                                    : 'text-slate-400 hover:text-slate-100 hover:bg-slate-800'
                            )}
                        >
                            <Icon size={17} className={active ? 'text-violet-400' : 'text-slate-500 group-hover:text-slate-300'} />
                            {label}
                            {active && <ChevronRight size={13} className="ml-auto text-violet-500" />}
                        </Link>
                    );
                })}
            </nav>

            {/* User */}
            <div className="px-4 py-4 border-t border-slate-800">
                <div className="flex items-center gap-3 mb-3">
                    <div className="w-8 h-8 rounded-full bg-gradient-to-br from-violet-500 to-indigo-600 flex items-center justify-center text-white text-xs font-bold">
                        {user?.ad?.[0]?.toUpperCase() ?? 'A'}
                    </div>
                    <div className="flex-1 min-w-0">
                        <p className="text-sm font-medium text-slate-100 truncate">{user?.ad} {user?.soyad}</p>
                        <p className="text-[11px] text-violet-400">Admin</p>
                    </div>
                </div>
                <button
                    onClick={logout}
                    className="w-full flex items-center gap-2.5 px-3 py-2 text-sm text-slate-400 hover:text-red-400 hover:bg-red-950/30 rounded-lg transition-all"
                >
                    <LogOut size={15} />
                    Çıkış Yap
                </button>
            </div>
        </aside>
    );
}
