'use client';
import { useEffect, useState } from 'react';
import { useAuth } from '@/lib/auth';
import { getAdminUserStats, getAdminListingStats } from '@/lib/api';
import { Users, Home, Clock, Eye, TrendingUp, ShieldBan, UserCheck } from 'lucide-react';
import { AreaChart, Area, XAxis, YAxis, Tooltip, ResponsiveContainer } from 'recharts';

interface UserStats { total: number; newLast7Days: number; newLast30Days: number; banned: number; admins: number; emlakcis: number; }
interface ListingStats { total: number; active: number; pending: number; newLast7Days: number; newLast30Days: number; totalViews: number; }

const mockChartData = Array.from({ length: 14 }, (_, i) => ({
    day: `${i + 1}`,
    ilanlar: Math.floor(Math.random() * 20) + 5,
    kullaniciler: Math.floor(Math.random() * 10) + 2,
}));

function StatCard({ icon: Icon, label, value, sub, color }: { icon: React.ElementType; label: string; value: number | string; sub?: string; color: string }) {
    return (
        <div className="bg-slate-900 border border-slate-800 rounded-2xl p-5">
            <div className="flex items-center justify-between mb-4">
                <p className="text-sm text-slate-400 font-medium">{label}</p>
                <div className={`w-9 h-9 rounded-xl flex items-center justify-center ${color}`}>
                    <Icon size={17} className="text-white" />
                </div>
            </div>
            <p className="text-3xl font-bold text-white">{typeof value === 'number' ? value.toLocaleString('tr-TR') : value}</p>
            {sub && <p className="text-xs text-slate-500 mt-1">{sub}</p>}
        </div>
    );
}

export default function DashboardPage() {
    const { token } = useAuth();
    const [userStats, setUserStats] = useState<UserStats | null>(null);
    const [listingStats, setListingStats] = useState<ListingStats | null>(null);

    useEffect(() => {
        if (!token) return;
        getAdminUserStats(token).then(setUserStats).catch(console.error);
        getAdminListingStats(token).then(setListingStats).catch(console.error);
    }, [token]);

    return (
        <div className="p-8">
            <div className="mb-8">
                <h1 className="text-2xl font-bold text-white">Dashboard</h1>
                <p className="text-slate-400 text-sm mt-1">EsaEmlak platformu genel görünümü</p>
            </div>

            <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
                <StatCard icon={Users} label="Toplam Kullanıcı" value={userStats?.total ?? '—'} sub={`Son 30 gün: +${userStats?.newLast30Days ?? 0}`} color="bg-violet-600" />
                <StatCard icon={Home} label="Toplam İlan" value={listingStats?.total ?? '—'} sub={`Aktif: ${listingStats?.active ?? 0}`} color="bg-indigo-600" />
                <StatCard icon={Clock} label="Bekleyen İlanlar" value={listingStats?.pending ?? '—'} sub="Onay bekliyor" color="bg-amber-600" />
                <StatCard icon={Eye} label="Toplam Görüntülenme" value={listingStats?.totalViews ?? '—'} sub="Tüm zamanlar" color="bg-emerald-600" />
            </div>

            <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
                <StatCard icon={TrendingUp} label="Bu Hafta Kullanıcı" value={userStats?.newLast7Days ?? '—'} color="bg-sky-600" />
                <StatCard icon={UserCheck} label="Emlakçılar" value={userStats?.emlakcis ?? '—'} color="bg-teal-600" />
                <StatCard icon={ShieldBan} label="Banlı Kullanıcı" value={userStats?.banned ?? '—'} color="bg-red-700" />
                <StatCard icon={Home} label="Bu Hafta İlan" value={listingStats?.newLast7Days ?? '—'} color="bg-pink-600" />
            </div>

            <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6">
                <h2 className="text-base font-semibold text-white mb-6">Son 14 Gün Aktivitesi</h2>
                <ResponsiveContainer width="100%" height={220}>
                    <AreaChart data={mockChartData}>
                        <defs>
                            <linearGradient id="colorIlan" x1="0" y1="0" x2="0" y2="1">
                                <stop offset="5%" stopColor="#7c3aed" stopOpacity={0.3} />
                                <stop offset="95%" stopColor="#7c3aed" stopOpacity={0} />
                            </linearGradient>
                            <linearGradient id="colorUser" x1="0" y1="0" x2="0" y2="1">
                                <stop offset="5%" stopColor="#4f46e5" stopOpacity={0.3} />
                                <stop offset="95%" stopColor="#4f46e5" stopOpacity={0} />
                            </linearGradient>
                        </defs>
                        <XAxis dataKey="day" stroke="#475569" tick={{ fontSize: 11 }} />
                        <YAxis stroke="#475569" tick={{ fontSize: 11 }} />
                        <Tooltip contentStyle={{ backgroundColor: '#0f172a', border: '1px solid #1e293b', borderRadius: 8, fontSize: 12 }} />
                        <Area type="monotone" dataKey="ilanlar" stroke="#7c3aed" strokeWidth={2} fill="url(#colorIlan)" name="İlanlar" />
                        <Area type="monotone" dataKey="kullaniciler" stroke="#4f46e5" strokeWidth={2} fill="url(#colorUser)" name="Kullanıcılar" />
                    </AreaChart>
                </ResponsiveContainer>
            </div>
        </div>
    );
}
