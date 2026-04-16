'use client';
import { useEffect, useState, useCallback } from 'react';
import { useAuth } from '@/lib/auth';
import { getAdminPayments } from '@/lib/api';
import { CreditCard } from 'lucide-react';

interface Payment {
    id: string; userId: string; amount: number; currency: string;
    status: string; description: string; createdAt: string;
}

const STATUS_COLORS: Record<string, string> = {
    completed: 'bg-emerald-950/50 text-emerald-400 border-emerald-800',
    pending: 'bg-amber-950/50 text-amber-400 border-amber-800',
    failed: 'bg-red-950/50 text-red-400 border-red-800',
    refunded: 'bg-blue-950/50 text-blue-400 border-blue-800',
};

export default function PaymentsPage() {
    const { token } = useAuth();
    const [payments, setPayments] = useState<Payment[]>([]);
    const [total, setTotal] = useState(0);
    const [loading, setLoading] = useState(false);

    const fetchPayments = useCallback(async () => {
        if (!token) return;
        setLoading(true);
        try {
            const data = await getAdminPayments(token, { skip: 0, limit: 50 });
            setPayments(data.payments ?? []);
            setTotal(data.total ?? 0);
        } catch (e) { console.error(e); }
        finally { setLoading(false); }
    }, [token]);

    useEffect(() => { fetchPayments(); }, [fetchPayments]);

    const totalRevenue = payments.filter(p => p.status === 'completed').reduce((s, p) => s + p.amount, 0);

    return (
        <div className="p-8">
            <div className="mb-6 flex items-center justify-between">
                <div>
                    <h1 className="text-2xl font-bold text-white">Ödeme Takibi</h1>
                    <p className="text-slate-400 text-sm mt-1">Toplam {total} ödeme</p>
                </div>
                {payments.length > 0 && (
                    <div className="bg-slate-900 border border-emerald-800/50 rounded-2xl px-6 py-3 text-right">
                        <p className="text-xs text-slate-500">Toplam Gelir</p>
                        <p className="text-xl font-bold text-emerald-400">₺{totalRevenue.toLocaleString('tr-TR')}</p>
                    </div>
                )}
            </div>

            <div className="bg-slate-900 border border-slate-800 rounded-2xl overflow-hidden">
                {loading ? (
                    <div className="text-center py-16 text-slate-500 text-sm">Yükleniyor...</div>
                ) : payments.length === 0 ? (
                    <div className="text-center py-16">
                        <CreditCard size={36} className="text-slate-700 mx-auto mb-3" />
                        <p className="text-slate-500 text-sm">
                            Ödeme verisi yok veya PaymentService admin endpoint&#39;i henüz uygulanmadı.
                        </p>
                    </div>
                ) : (
                    <table className="w-full">
                        <thead>
                            <tr className="border-b border-slate-800 text-xs text-slate-500 uppercase tracking-wider">
                                <th className="text-left px-5 py-3.5">ID</th>
                                <th className="text-left px-5 py-3.5">Kullanıcı</th>
                                <th className="text-left px-5 py-3.5">Tutar</th>
                                <th className="text-left px-5 py-3.5">Açıklama</th>
                                <th className="text-left px-5 py-3.5">Durum</th>
                                <th className="text-left px-5 py-3.5">Tarih</th>
                            </tr>
                        </thead>
                        <tbody>
                            {payments.map(p => (
                                <tr key={p.id} className="border-b border-slate-800/50 hover:bg-slate-800/30 transition-colors">
                                    <td className="px-5 py-3 text-xs text-slate-500 font-mono">{p.id?.slice(-8)}</td>
                                    <td className="px-5 py-3 text-xs text-slate-400 font-mono">{p.userId?.slice(-8)}</td>
                                    <td className="px-5 py-3 text-sm font-semibold text-emerald-400">₺{p.amount?.toLocaleString('tr-TR')} <span className="text-xs text-slate-500">{p.currency}</span></td>
                                    <td className="px-5 py-3 text-sm text-slate-400 max-w-[200px] truncate">{p.description}</td>
                                    <td className="px-5 py-3">
                                        <span className={`px-2.5 py-0.5 rounded-lg text-xs font-medium border ${STATUS_COLORS[p.status] ?? 'bg-slate-800 text-slate-400 border-slate-700'}`}>
                                            {p.status}
                                        </span>
                                    </td>
                                    <td className="px-5 py-3 text-xs text-slate-500">{new Date(p.createdAt).toLocaleDateString('tr-TR')}</td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                )}
            </div>
        </div>
    );
}
