'use client';
import { useEffect, useState, useCallback } from 'react';
import { useAuth } from '@/lib/auth';
import { getAdminUsers, banUser, updateUserRol, createAdminUser, updateAdminUser, deleteAdminUser } from '@/lib/api';
import { Search, ShieldBan, ShieldCheck, ChevronLeft, ChevronRight, UserCog, UserPlus, Pencil, Trash2, X, Check } from 'lucide-react';
import clsx from 'clsx';

interface User {
    id: string; ad: string; soyad: string; email: string; telefon: string;
    rol: string; onayli: boolean; banli: boolean; createdAt: string;
}

const ROL_COLORS: Record<string, string> = {
    admin: 'bg-violet-900/50 text-violet-300 border border-violet-700',
    emlakci: 'bg-indigo-900/50 text-indigo-300 border border-indigo-700',
    kullanici: 'bg-slate-800 text-slate-400 border border-slate-700',
};

const emptyForm = { ad: '', soyad: '', email: '', telefon: '', password: '', rol: 'kullanici', onayli: false };

interface ModalProps {
    title: string;
    onClose: () => void;
    onSubmit: () => void;
    loading: boolean;
    error: string;
    children: React.ReactNode;
}

function Modal({ title, onClose, onSubmit, loading, error, children }: ModalProps) {
    return (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/70 backdrop-blur-sm">
            <div className="bg-slate-900 border border-slate-700 rounded-2xl w-full max-w-md mx-4 shadow-2xl">
                <div className="flex items-center justify-between px-6 py-4 border-b border-slate-800">
                    <h2 className="text-base font-semibold text-white">{title}</h2>
                    <button onClick={onClose} className="text-slate-500 hover:text-white transition"><X size={18} /></button>
                </div>
                <div className="px-6 py-5 space-y-4">
                    {error && <p className="text-sm text-red-400 bg-red-950/40 border border-red-800 rounded-xl px-4 py-2.5">{error}</p>}
                    {children}
                </div>
                <div className="flex gap-3 px-6 py-4 border-t border-slate-800">
                    <button onClick={onClose} className="flex-1 px-4 py-2.5 rounded-xl border border-slate-700 text-slate-300 text-sm hover:bg-slate-800 transition">İptal</button>
                    <button
                        onClick={onSubmit}
                        disabled={loading}
                        className="flex-1 px-4 py-2.5 rounded-xl bg-violet-600 hover:bg-violet-500 text-white text-sm font-medium transition disabled:opacity-50 flex items-center justify-center gap-2"
                    >
                        {loading ? 'Kaydediliyor...' : <><Check size={14} /> Kaydet</>}
                    </button>
                </div>
            </div>
        </div>
    );
}

const inputCls = "w-full bg-slate-950 border border-slate-700 rounded-xl px-4 py-2.5 text-sm text-white placeholder:text-slate-500 focus:outline-none focus:border-violet-500";
const labelCls = "block text-xs text-slate-400 mb-1.5";

type FormState = { ad: string; soyad: string; email: string; telefon: string; password: string; rol: string; onayli: boolean; };

function FormFields({ form, setForm, showPassword }: { form: FormState; setForm: React.Dispatch<React.SetStateAction<FormState>>; showPassword: boolean }) {
    return (
        <>
            <div className="grid grid-cols-2 gap-3">
                <div><label className={labelCls}>Ad</label><input value={form.ad} onChange={e => setForm(f => ({ ...f, ad: e.target.value }))} className={inputCls} placeholder="Ad" /></div>
                <div><label className={labelCls}>Soyad</label><input value={form.soyad} onChange={e => setForm(f => ({ ...f, soyad: e.target.value }))} className={inputCls} placeholder="Soyad" /></div>
            </div>
            <div><label className={labelCls}>E-posta</label><input type="email" value={form.email} onChange={e => setForm(f => ({ ...f, email: e.target.value }))} className={inputCls} placeholder="ornek@mail.com" /></div>
            <div><label className={labelCls}>Telefon</label><input value={form.telefon} onChange={e => setForm(f => ({ ...f, telefon: e.target.value }))} className={inputCls} placeholder="5XXXXXXXXX" /></div>
            <div>
                <label className={labelCls}>{showPassword ? 'Şifre' : 'Yeni Şifre (boş bırakılabilir)'}</label>
                <input type="password" value={form.password} onChange={e => setForm(f => ({ ...f, password: e.target.value }))} className={inputCls} placeholder={showPassword ? 'Şifre girin' : 'Değiştirmek istiyorsanız girin'} />
            </div>
            <div className="grid grid-cols-2 gap-3">
                <div>
                    <label className={labelCls}>Rol</label>
                    <select value={form.rol} onChange={e => setForm(f => ({ ...f, rol: e.target.value }))} className={inputCls}>
                        <option value="kullanici">Kullanıcı</option>
                        <option value="emlakci">Emlakçı</option>
                        <option value="admin">Admin</option>
                    </select>
                </div>
                <div>
                    <label className={labelCls}>Durum</label>
                    <select value={form.onayli ? 'true' : 'false'} onChange={e => setForm(f => ({ ...f, onayli: e.target.value === 'true' }))} className={inputCls}>
                        <option value="true">Onaylı</option>
                        <option value="false">Onaysız</option>
                    </select>
                </div>
            </div>
        </>
    );
}

export default function UsersPage() {
    const { token } = useAuth();
    const [users, setUsers] = useState<User[]>([]);
    const [total, setTotal] = useState(0);
    const [page, setPage] = useState(0);
    const [search, setSearch] = useState('');
    const [rolFilter, setRolFilter] = useState('');
    const [loading, setLoading] = useState(false);
    const limit = 15;

    // Modal states
    const [showCreate, setShowCreate] = useState(false);
    const [showEdit, setShowEdit] = useState(false);
    const [editUser, setEditUser] = useState<User | null>(null);
    const [form, setForm] = useState({ ...emptyForm });
    const [modalLoading, setModalLoading] = useState(false);
    const [modalError, setModalError] = useState('');

    const fetchUsers = useCallback(async () => {
        if (!token) return;
        setLoading(true);
        try {
            const params: Record<string, string | number> = { skip: page * limit, limit };
            if (search) params.search = search;
            if (rolFilter) params.rol = rolFilter;
            const data = await getAdminUsers(token, params);
            setUsers(data.users);
            setTotal(data.total);
        } catch (e) { console.error(e); }
        finally { setLoading(false); }
    }, [token, page, search, rolFilter, limit]);

    useEffect(() => { fetchUsers(); }, [fetchUsers]);

    const handleBan = async (id: string) => {
        if (!token) return;
        await banUser(token, id);
        fetchUsers();
    };

    const handleRolCycle = async (id: string, currentRol: string) => {
        if (!token) return;
        const roles = ['kullanici', 'emlakci', 'admin'];
        const nextRol = roles[(roles.indexOf(currentRol) + 1) % roles.length];
        if (!confirm(`Rol değiştirilecek: ${currentRol} → ${nextRol}`)) return;
        await updateUserRol(token, id, nextRol);
        fetchUsers();
    };

    const openCreate = () => {
        setForm({ ...emptyForm });
        setModalError('');
        setShowCreate(true);
    };

    const openEdit = (u: User) => {
        setEditUser(u);
        setForm({ ad: u.ad, soyad: u.soyad, email: u.email, telefon: u.telefon, password: '', rol: u.rol, onayli: u.onayli });
        setModalError('');
        setShowEdit(true);
    };

    const handleCreate = async () => {
        if (!token) return;
        setModalLoading(true);
        setModalError('');
        try {
            await createAdminUser(token, form);
            setShowCreate(false);
            fetchUsers();
        } catch (e: unknown) {
            setModalError(e instanceof Error ? e.message : 'Hata oluştu');
        } finally { setModalLoading(false); }
    };

    const handleEdit = async () => {
        if (!token || !editUser) return;
        setModalLoading(true);
        setModalError('');
        try {
            await updateAdminUser(token, editUser.id, form);
            setShowEdit(false);
            fetchUsers();
        } catch (e: unknown) {
            setModalError(e instanceof Error ? e.message : 'Hata oluştu');
        } finally { setModalLoading(false); }
    };

    const handleDelete = async (u: User) => {
        if (!token || !confirm(`"${u.ad} ${u.soyad}" kullanıcısı silinecek. Emin misin?`)) return;
        await deleteAdminUser(token, u.id);
        fetchUsers();
    };

    const totalPages = Math.ceil(total / limit);


    return (
        <div className="p-8">
            <div className="flex items-center justify-between mb-6">
                <div>
                    <h1 className="text-2xl font-bold text-white">Kullanıcı Yönetimi</h1>
                    <p className="text-slate-400 text-sm mt-1">Toplam {total} kullanıcı</p>
                </div>
                <button
                    onClick={openCreate}
                    className="flex items-center gap-2 px-4 py-2.5 rounded-xl bg-violet-600 hover:bg-violet-500 text-white text-sm font-medium transition"
                >
                    <UserPlus size={15} /> Kullanıcı Ekle
                </button>
            </div>

            {/* Filters */}
            <div className="flex gap-3 mb-6">
                <div className="relative flex-1 max-w-sm">
                    <Search size={15} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-500" />
                    <input
                        value={search}
                        onChange={e => { setSearch(e.target.value); setPage(0); }}
                        placeholder="İsim veya e-posta ara..."
                        className="w-full bg-slate-900 border border-slate-800 rounded-xl py-2.5 pl-10 pr-4 text-sm text-white placeholder:text-slate-500 focus:outline-none focus:border-violet-600"
                    />
                </div>
                <select
                    value={rolFilter}
                    onChange={e => { setRolFilter(e.target.value); setPage(0); }}
                    className="bg-slate-900 border border-slate-800 rounded-xl px-4 py-2.5 text-sm text-white focus:outline-none focus:border-violet-600"
                >
                    <option value="">Tüm Roller</option>
                    <option value="kullanici">Kullanıcı</option>
                    <option value="emlakci">Emlakçı</option>
                    <option value="admin">Admin</option>
                </select>
            </div>

            {/* Table */}
            <div className="bg-slate-900 border border-slate-800 rounded-2xl overflow-hidden">
                <table className="w-full">
                    <thead>
                        <tr className="border-b border-slate-800 text-xs text-slate-500 uppercase tracking-wider">
                            <th className="text-left px-5 py-3.5">Kullanıcı</th>
                            <th className="text-left px-5 py-3.5">Telefon</th>
                            <th className="text-left px-5 py-3.5">Rol</th>
                            <th className="text-left px-5 py-3.5">Durum</th>
                            <th className="text-left px-5 py-3.5">Kayıt Tarihi</th>
                            <th className="text-right px-5 py-3.5">İşlemler</th>
                        </tr>
                    </thead>
                    <tbody>
                        {loading ? (
                            <tr><td colSpan={6} className="text-center py-12 text-slate-500 text-sm">Yükleniyor...</td></tr>
                        ) : users.length === 0 ? (
                            <tr><td colSpan={6} className="text-center py-12 text-slate-500 text-sm">Kullanıcı bulunamadı</td></tr>
                        ) : users.map(u => (
                            <tr key={u.id} className="border-b border-slate-800/50 hover:bg-slate-800/30 transition-colors">
                                <td className="px-5 py-4">
                                    <div className="flex items-center gap-3">
                                        <div className="w-8 h-8 rounded-full bg-gradient-to-br from-violet-600 to-indigo-700 flex items-center justify-center text-white text-xs font-bold">
                                            {u.ad?.[0]?.toUpperCase()}
                                        </div>
                                        <div>
                                            <p className="text-sm font-medium text-white">{u.ad} {u.soyad}</p>
                                            <p className="text-xs text-slate-500">{u.email}</p>
                                        </div>
                                    </div>
                                </td>
                                <td className="px-5 py-4 text-sm text-slate-400">{u.telefon}</td>
                                <td className="px-5 py-4">
                                    <span className={clsx('px-2.5 py-1 rounded-lg text-xs font-medium', ROL_COLORS[u.rol])}>
                                        {u.rol}
                                    </span>
                                </td>
                                <td className="px-5 py-4">
                                    {u.banli
                                        ? <span className="px-2.5 py-1 rounded-lg text-xs font-medium bg-red-950/50 text-red-400 border border-red-800">Banlı</span>
                                        : u.onayli
                                            ? <span className="px-2.5 py-1 rounded-lg text-xs font-medium bg-emerald-950/50 text-emerald-400 border border-emerald-800">Aktif</span>
                                            : <span className="px-2.5 py-1 rounded-lg text-xs font-medium bg-amber-950/50 text-amber-400 border border-amber-800">Onaysız</span>
                                    }
                                </td>
                                <td className="px-5 py-4 text-xs text-slate-500">{new Date(u.createdAt).toLocaleDateString('tr-TR')}</td>
                                <td className="px-5 py-4">
                                    <div className="flex items-center justify-end gap-1.5">
                                        <button onClick={() => openEdit(u)} title="Düzenle" className="p-1.5 rounded-lg text-blue-400 hover:bg-blue-950/40 transition-all">
                                            <Pencil size={14} />
                                        </button>
                                        <button onClick={() => handleBan(u.id)} title={u.banli ? 'Ban Kaldır' : 'Banla'}
                                            className={clsx('p-1.5 rounded-lg transition-all', u.banli ? 'text-emerald-500 hover:bg-emerald-950/40' : 'text-orange-500 hover:bg-orange-950/40')}>
                                            {u.banli ? <ShieldCheck size={14} /> : <ShieldBan size={14} />}
                                        </button>
                                        <button onClick={() => handleRolCycle(u.id, u.rol)} title="Rol Değiştir" className="p-1.5 rounded-lg text-violet-400 hover:bg-violet-950/40 transition-all">
                                            <UserCog size={14} />
                                        </button>
                                        <button onClick={() => handleDelete(u)} title="Sil" className="p-1.5 rounded-lg text-red-500 hover:bg-red-950/40 transition-all">
                                            <Trash2 size={14} />
                                        </button>
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
                            <button disabled={page === 0} onClick={() => setPage(p => p - 1)} className="p-1.5 rounded-lg text-slate-400 hover:bg-slate-800 disabled:opacity-30 transition"><ChevronLeft size={15} /></button>
                            <button disabled={page >= totalPages - 1} onClick={() => setPage(p => p + 1)} className="p-1.5 rounded-lg text-slate-400 hover:bg-slate-800 disabled:opacity-30 transition"><ChevronRight size={15} /></button>
                        </div>
                    </div>
                )}
            </div>

            {/* Create Modal */}
            {showCreate && (
                <Modal title="Yeni Kullanıcı Ekle" onClose={() => setShowCreate(false)} onSubmit={handleCreate} loading={modalLoading} error={modalError}>
                    <FormFields form={form} setForm={setForm} showPassword={true} />
                </Modal>
            )}

            {/* Edit Modal */}
            {showEdit && editUser && (
                <Modal title={`Düzenle: ${editUser.ad} ${editUser.soyad}`} onClose={() => setShowEdit(false)} onSubmit={handleEdit} loading={modalLoading} error={modalError}>
                    <FormFields form={form} setForm={setForm} showPassword={false} />
                </Modal>
            )}
        </div>
    );
}
