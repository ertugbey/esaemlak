'use client';
import { useEffect, useState, useCallback } from 'react';
import { useAuth } from '@/lib/auth';
import { getPendingListings, approveListing, rejectListing } from '@/lib/api';
import { CheckCircle, XCircle, Clock, ChevronLeft, ChevronRight } from 'lucide-react';

interface Listing {
    id: string; emlakciId: string; baslik: string; aciklama: string;
    kategori: string; altKategori: string; islemTipi: string; fiyat: number;
    il: string; ilce: string; mahalle: string; brutMetrekare: number;
    odaSayisi: string; fotograflar: string[]; createdAt: string;
}

export default function PendingListingsPage() {
    const { token } = useAuth();
    const [listings, setListings] = useState<Listing[]>([]);
    const [total, setTotal] = useState(0);
    const [page, setPage] = useState(0);
    const [loading, setLoading] = useState(false);
    const limit = 10;

    const fetchPending = useCallback(async () => {
        if (!token) return;
        setLoading(true);
        try {
            const data = await getPendingListings(token, { skip: page * limit, limit });
            setListings(data.listings);
            setTotal(data.total);
        } catch (e) { console.error(e); }
        finally { setLoading(false); }
    }, [token, page, limit]);

    useEffect(() => { fetchPending(); }, [fetchPending]);

    const handle = async (id: string, action: 'approve' | 'reject') => {
        if (!token) return;
        if (action === 'approve') await approveListing(token, id);
        else await rejectListing(token, id);
        fetchPending();
    };

    const totalPages = Math.ceil(total / limit);

    return (
        <div className="p-8">
            <div className="mb-6 flex items-center gap-3">
                <div className="w-10 h-10 rounded-xl bg-amber-600/20 border border-amber-600/30 flex items-center justify-center">
                    <Clock size={18} className="text-amber-400" />
                </div>
                <div>
                    <h1 className="text-2xl font-bold text-white">Bekleyen İlanlar</h1>
                    <p className="text-slate-400 text-sm">{total} ilan onay bekliyor</p>
                </div>
            </div>

            {loading ? (
                <div className="flex justify-center py-20"><div className="w-8 h-8 border-2 border-violet-600 border-t-transparent rounded-full animate-spin" /></div>
            ) : listings.length === 0 ? (
                <div className="bg-slate-900 border border-slate-800 rounded-2xl p-16 text-center">
                    <CheckCircle size={40} className="text-emerald-500 mx-auto mb-4" />
                    <p className="text-slate-300 font-medium">Harika! Bekleyen ilan yok.</p>
                    <p className="text-slate-500 text-sm mt-1">Tüm ilanlar incelendi.</p>
                </div>
            ) : (
                <div className="space-y-4">
                    {listings.map(l => (
                        <div key={l.id} className="bg-slate-900 border border-slate-800 rounded-2xl overflow-hidden hover:border-slate-700 transition-colors">
                            <div className="flex gap-4 p-5">
                                {/* Thumbnail */}
                                <div className="flex-shrink-0">
                                    {l.fotograflar?.[0]
                                        ? <img src={l.fotograflar[0]} alt="" className="w-28 h-20 object-cover rounded-xl" />
                                        : <div className="w-28 h-20 bg-slate-800 rounded-xl flex items-center justify-center text-slate-600 text-xs">Fotoğraf yok</div>}
                                </div>
                                {/* Info */}
                                <div className="flex-1 min-w-0">
                                    <div className="flex items-start justify-between gap-4">
                                        <div>
                                            <h3 className="font-semibold text-white">{l.baslik}</h3>
                                            <p className="text-sm text-slate-400 mt-0.5">{l.il} / {l.ilce}{l.mahalle ? ` / ${l.mahalle}` : ''}</p>
                                        </div>
                                        <p className="text-lg font-bold text-emerald-400 flex-shrink-0">₺{l.fiyat?.toLocaleString('tr-TR')}</p>
                                    </div>
                                    <div className="flex gap-2 mt-2 flex-wrap">
                                        <span className="px-2 py-0.5 bg-slate-800 border border-slate-700 rounded-md text-xs text-slate-400">{l.kategori}</span>
                                        <span className="px-2 py-0.5 bg-slate-800 border border-slate-700 rounded-md text-xs text-slate-400">{l.islemTipi}</span>
                                        {l.brutMetrekare && <span className="px-2 py-0.5 bg-slate-800 border border-slate-700 rounded-md text-xs text-slate-400">{l.brutMetrekare} m²</span>}
                                        {l.odaSayisi && <span className="px-2 py-0.5 bg-slate-800 border border-slate-700 rounded-md text-xs text-slate-400">{l.odaSayisi}</span>}
                                    </div>
                                    {l.aciklama && <p className="text-xs text-slate-500 mt-2 line-clamp-2">{l.aciklama}</p>}
                                </div>
                            </div>
                            {/* Actions */}
                            <div className="border-t border-slate-800 px-5 py-3 flex items-center justify-between">
                                <p className="text-xs text-slate-500">{new Date(l.createdAt).toLocaleDateString('tr-TR')} tarihinde eklendi</p>
                                <div className="flex gap-3">
                                    <button onClick={() => handle(l.id, 'reject')}
                                        className="flex items-center gap-1.5 px-4 py-1.5 rounded-xl text-sm font-medium text-red-400 bg-red-950/30 border border-red-900/50 hover:bg-red-950/60 transition-all">
                                        <XCircle size={14} /> Reddet
                                    </button>
                                    <button onClick={() => handle(l.id, 'approve')}
                                        className="flex items-center gap-1.5 px-4 py-1.5 rounded-xl text-sm font-medium text-emerald-400 bg-emerald-950/30 border border-emerald-900/50 hover:bg-emerald-950/60 transition-all">
                                        <CheckCircle size={14} /> Onayla
                                    </button>
                                </div>
                            </div>
                        </div>
                    ))}

                    {totalPages > 1 && (
                        <div className="flex items-center justify-between pt-2">
                            <p className="text-xs text-slate-500">{page * limit + 1}–{Math.min((page + 1) * limit, total)} / {total}</p>
                            <div className="flex gap-2">
                                <button disabled={page === 0} onClick={() => setPage(p => p - 1)} className="p-2 rounded-lg text-slate-400 hover:bg-slate-800 disabled:opacity-30"><ChevronLeft size={15} /></button>
                                <button disabled={page >= totalPages - 1} onClick={() => setPage(p => p + 1)} className="p-2 rounded-lg text-slate-400 hover:bg-slate-800 disabled:opacity-30"><ChevronRight size={15} /></button>
                            </div>
                        </div>
                    )}
                </div>
            )}
        </div>
    );
}
