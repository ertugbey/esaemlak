'use client';
import { useEffect, useState, useCallback } from 'react';
import { useAuth } from '@/lib/auth';
import { getAdminMessages } from '@/lib/api';
import { MessageSquare, Search } from 'lucide-react';

interface Message {
    id: string; senderId: string; receiverId: string; content: string;
    createdAt: string; isRead: boolean;
}

export default function MessagesPage() {
    const { token } = useAuth();
    const [messages, setMessages] = useState<Message[]>([]);
    const [total, setTotal] = useState(0);
    const [search, setSearch] = useState('');
    const [loading, setLoading] = useState(false);

    const fetchMessages = useCallback(async () => {
        if (!token) return;
        setLoading(true);
        try {
            const data = await getAdminMessages(token, { skip: 0, limit: 50 });
            setMessages(data.messages ?? []);
            setTotal(data.total ?? 0);
        } catch (e) { console.error(e); }
        finally { setLoading(false); }
    }, [token]);

    useEffect(() => { fetchMessages(); }, [fetchMessages]);

    const filtered = messages.filter(m =>
        m.content?.toLowerCase().includes(search.toLowerCase())
    );

    return (
        <div className="p-8">
            <div className="mb-6">
                <h1 className="text-2xl font-bold text-white">Mesaj Moderasyonu</h1>
                <p className="text-slate-400 text-sm mt-1">Toplam {total} mesaj</p>
            </div>

            <div className="relative mb-6 max-w-sm">
                <Search size={15} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-500" />
                <input value={search} onChange={e => setSearch(e.target.value)} placeholder="Mesaj içeriği ara..."
                    className="w-full bg-slate-900 border border-slate-800 rounded-xl py-2.5 pl-10 pr-4 text-sm text-white placeholder:text-slate-500 focus:outline-none focus:border-violet-600" />
            </div>

            <div className="bg-slate-900 border border-slate-800 rounded-2xl overflow-hidden">
                {loading ? (
                    <div className="text-center py-16 text-slate-500 text-sm">Yükleniyor...</div>
                ) : filtered.length === 0 ? (
                    <div className="text-center py-16">
                        <MessageSquare size={36} className="text-slate-700 mx-auto mb-3" />
                        <p className="text-slate-500 text-sm">
                            {messages.length === 0 ? 'Mesaj yok veya MessagingService admin endpoint\'i henüz uygulanmadı.' : 'Eşleşen mesaj bulunamadı.'}
                        </p>
                    </div>
                ) : (
                    <table className="w-full">
                        <thead>
                            <tr className="border-b border-slate-800 text-xs text-slate-500 uppercase tracking-wider">
                                <th className="text-left px-5 py-3.5">Gönderen</th>
                                <th className="text-left px-5 py-3.5">Alıcı</th>
                                <th className="text-left px-5 py-3.5">İçerik</th>
                                <th className="text-left px-5 py-3.5">Tarih</th>
                                <th className="text-left px-5 py-3.5">Durum</th>
                            </tr>
                        </thead>
                        <tbody>
                            {filtered.map(m => (
                                <tr key={m.id} className="border-b border-slate-800/50 hover:bg-slate-800/30 transition-colors">
                                    <td className="px-5 py-3 text-sm text-slate-300 font-mono text-xs">{m.senderId?.slice(-8)}</td>
                                    <td className="px-5 py-3 text-sm text-slate-300 font-mono text-xs">{m.receiverId?.slice(-8)}</td>
                                    <td className="px-5 py-3 text-sm text-slate-400 max-w-[300px]">
                                        <p className="truncate">{m.content}</p>
                                    </td>
                                    <td className="px-5 py-3 text-xs text-slate-500">{new Date(m.createdAt).toLocaleDateString('tr-TR')}</td>
                                    <td className="px-5 py-3">
                                        {m.isRead
                                            ? <span className="px-2 py-0.5 rounded text-xs bg-slate-800 text-slate-500">Okundu</span>
                                            : <span className="px-2 py-0.5 rounded text-xs bg-violet-900/40 text-violet-300 border border-violet-800">Yeni</span>}
                                    </td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                )}
            </div>
        </div>
    );
}
