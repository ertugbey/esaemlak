'use client';
import { useEffect, useState, useCallback } from 'react';
import { useAuth } from '@/lib/auth';
import { getAdminListings, adminDeleteListing, rejectListing, approveListing } from '@/lib/api';
import { Search, Trash2, XCircle, CheckCircle, ChevronLeft, ChevronRight, Eye } from 'lucide-react';

interface Listing {
    id: string; emlakciId: string; baslik: string; kategori: string; islemTipi: string;
    fiyat: number; il: string; ilce: string; aktif: boolean; onaylandi: boolean;
    goruntulemeSayisi: number; fotograflar: string[]; createdAt: string;
}

export default function ListingsPage() {
    const { token } = useAuth();
    const [listings, setListings] = useState<Listing[]>([]);
    const [total, setTotal] = useState(0);
    const [page, setPage] = useState(0);
    const [search, setSearch] = useState('');
    const [kategori, setKategori] = useState('');
    const [aktifFilter, setAktifFilter] = useState('');
    const [loading, setLoading] = useState(false);
    const limit = 15;

    const fetchListings = useCallback(async () => {
        if (!token) return;
        setLoading(true);
        try {
            const params: Record<string, string | number | boolean> = { skip: page * limit, limit };
            if (search) params.search = search;
            if (kategori) params.kategori = kategori;
            if (aktifFilter !== '') params.aktif = aktifFilter === 'true';
            const data = await getAdminListings(token, params);
            setListings(data.listings);
            setTotal(data.total);
        } catch (e) { console.error(e); }
        finally { setLoading(false); }
    }, [token, page, search, kategori, aktifFilter, limit]);

    useEffect(() => { fetchListings(); }, [fetchListings]);

    const handleDelete = async (id: string, baslik: string) => {
        if (!token || !confirm(`"${baslik}" ilanı silinecek, emin misin?`)) return;
        await adminDeleteListing(token, id);
        fetchListings();
    };

    const handleReject = async (id: string) => {
        if (!token) return;
        await rejectListing(token, id);
        fetchListings();
    };

    const handleApprove = async (id: string) => {
        if (!token) return;
        await approveListing(token, id);
        fetchListings();
    };

    const totalPages = Math.ceil(total / limit);

    return (
        <div className="p-8">
            <div className="mb-6">
                <h1 className="text-2xl font-bold text-white">İlan Yönetimi</h1>
                <p className="text-slate-400 text-sm mt-1">Toplam {total} ilan</p>
            </div>

            {/* Filters */}
            <div className="flex gap-3 mb-6 flex-wrap">
                <div className="relative flex-1 min-w-[200px] max-w-sm">
                    <Search size={15} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-500" />
                    <input
                        value={search}
                        onChange={e => { setSearch(e.target.value); setPage(0); }}
                        placeholder="İlan ara..."
                        className="w-full bg-slate-900 border border-slate-800 rounded-xl py-2.5 pl-10 pr-4 text-sm text-white placeholder:text-slate-500 focus:outline-none focus:border-violet-600"
                    />
                </div>
                <select value={kategori} onChange={e => { setKategori(e.target.value); setPage(0); }}
                    className="bg-slate-900 border border-slate-800 rounded-xl px-4 py-2.5 text-sm text-white focus:outline-none focus:border-violet-600">
                    <option value="">Tüm Kategoriler</option>
                    <option value="Konut">Konut</option>
                    <option value="IsYeri">İş Yeri</option>
                    <option value="Arsa">Arsa</option>
                </select>
                <select value={aktifFilter} onChange={e => { setAktifFilter(e.target.value); setPage(0); }}
                    className="bg-slate-900 border border-slate-800 rounded-xl px-4 py-2.5 text-sm text-white focus:outline-none focus:border-violet-600">
                    <option value="">Tüm Durumlar</option>
                    <option value="true">Aktif</option>
                    <option value="false">Pasif</option>
                </select>
            </div>

            {/* Table */}
            <div className="bg-slate-900 border border-slate-800 rounded-2xl overflow-hidden">
                <table className="w-full">
                    <thead>
                        <tr className="border-b border-slate-800 text-xs text-slate-500 uppercase tracking-wider">
                            <th className="text-left px-5 py-3.5">İlan</th>
                            <th className="text-left px-5 py-3.5">Kategori</th>
                            <th className="text-left px-5 py-3.5">Fiyat</th>
                            <th className="text-left px-5 py-3.5">Konum</th>
                            <th className="text-left px-5 py-3.5">Görüntülenme</th>
                            <th className="text-left px-5 py-3.5">Durum</th>
                            <th className="text-right px-5 py-3.5">İşlemler</th>
                        </tr>
                    </thead>
                    <tbody>
                        {loading ? (
                            <tr><td colSpan={7} className="text-center py-12 text-slate-500 text-sm">Yükleniyor...</td></tr>
                        ) : listings.length === 0 ? (
                            <tr><td colSpan={7} className="text-center py-12 text-slate-500 text-sm">İlan bulunamadı</td></tr>
                        ) : listings.map(l => (
                            <tr key={l.id} className="border-b border-slate-800/50 hover:bg-slate-800/30 transition-colors">
                                <td className="px-5 py-4">
                                    <div className="flex items-center gap-3">
                                        {l.fotograflar?.[0]
                                            ? <img src={l.fotograflar[0]} alt="" className="w-10 h-10 rounded-lg object-cover" />
                                            : <div className="w-10 h-10 rounded-lg bg-slate-800 flex items-center justify-center text-slate-600 text-xs">No img</div>}
                                        <div>
                                            <p className="text-sm font-medium text-white max-w-[200px] truncate">{l.baslik}</p>
                                            <p className="text-xs text-slate-500">{new Date(l.createdAt).toLocaleDateString('tr-TR')}</p>
                                        </div>
                                    </div>
                                </td>
                                <td className="px-5 py-4"><span className="text-xs text-slate-300 bg-slate-800 px-2 py-1 rounded-lg">{l.kategori} · {l.islemTipi}</span></td>
                                <td className="px-5 py-4 text-sm text-emerald-400 font-medium">₺{l.fiyat?.toLocaleString('tr-TR')}</td>
                                <td className="px-5 py-4 text-sm text-slate-400">{l.il} / {l.ilce}</td>
                                <td className="px-5 py-4"><div className="flex items-center gap-1.5 text-sm text-slate-400"><Eye size={13} />{l.goruntulemeSayisi}</div></td>
                                <td className="px-5 py-4">
                                    {!l.aktif
                                        ? <span className="px-2.5 py-1 rounded-lg text-xs font-medium bg-red-950/50 text-red-400 border border-red-800">Pasif</span>
                                        : l.onaylandi
                                            ? <span className="px-2.5 py-1 rounded-lg text-xs font-medium bg-emerald-950/50 text-emerald-400 border border-emerald-800">Onaylı</span>
                                            : <span className="px-2.5 py-1 rounded-lg text-xs font-medium bg-amber-950/50 text-amber-400 border border-amber-800">Bekliyor</span>}
                                </td>
                                <td className="px-5 py-4">
                                    <div className="flex items-center justify-end gap-2">
                                        {!l.onaylandi && l.aktif && (
                                            <button onClick={() => handleApprove(l.id)} title="Onayla" className="p-1.5 rounded-lg text-emerald-400 hover:bg-emerald-950/40 transition"><CheckCircle size={15} /></button>
                                        )}
                                        {l.aktif && (
                                            <button onClick={() => handleReject(l.id)} title="Reddet" className="p-1.5 rounded-lg text-amber-400 hover:bg-amber-950/40 transition"><XCircle size={15} /></button>
                                        )}
                                        <button onClick={() => handleDelete(l.id, l.baslik)} title="Sil" className="p-1.5 rounded-lg text-red-400 hover:bg-red-950/40 transition"><Trash2 size={15} /></button>
                                    </div>
                                </td>
                            </tr>
                        ))}
                    </tbody>
                </table>
                {totalPages > 1 && (
                    <div className="px-5 py-3.5 border-t border-slate-800 flex items-center justify-between">
                        <p className="text-xs text-slate-500">{page * limit + 1}–{Math.min((page + 1) * limit, total)} / {total}</p>
                        <div className="flex gap-2">
                            <button disabled={page === 0} onClick={() => setPage(p => p - 1)} className="p-1.5 rounded-lg text-slate-400 hover:bg-slate-800 disabled:opacity-30"><ChevronLeft size={15} /></button>
                            <button disabled={page >= totalPages - 1} onClick={() => setPage(p => p + 1)} className="p-1.5 rounded-lg text-slate-400 hover:bg-slate-800 disabled:opacity-30"><ChevronRight size={15} /></button>
                        </div>
                    </div>
                )}
            </div>
        </div>
    );
}
