'use client';
import { useState, useEffect } from 'react';
import { Settings, Save, Globe } from 'lucide-react';

export default function SettingsPage() {
    const [apiUrl, setApiUrl] = useState('http://localhost:5000');
    const [saved, setSaved] = useState(false);

    useEffect(() => {
        const stored = localStorage.getItem('api_url');
        if (stored) setApiUrl(stored);
    }, []);


    const handleSave = () => {
        localStorage.setItem('api_url', apiUrl);
        setSaved(true);
        setTimeout(() => setSaved(false), 2000);
    };

    return (
        <div className="p-8">
            <div className="mb-6 flex items-center gap-3">
                <div className="w-10 h-10 rounded-xl bg-slate-800 border border-slate-700 flex items-center justify-center">
                    <Settings size={18} className="text-slate-400" />
                </div>
                <div>
                    <h1 className="text-2xl font-bold text-white">Ayarlar</h1>
                    <p className="text-slate-400 text-sm">Panel yapılandırması</p>
                </div>
            </div>

            <div className="max-w-lg space-y-4">
                {/* API URL */}
                <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6">
                    <h2 className="text-base font-semibold text-white mb-4 flex items-center gap-2">
                        <Globe size={16} className="text-violet-400" /> API Yapılandırması
                    </h2>
                    <div className="space-y-4">
                        <div>
                            <label className="text-xs text-slate-400 font-medium mb-1.5 block">API Gateway URL</label>
                            <input
                                value={apiUrl}
                                onChange={e => setApiUrl(e.target.value)}
                                className="w-full bg-slate-800 border border-slate-700 rounded-xl py-2.5 px-4 text-sm text-white focus:outline-none focus:border-violet-500 transition-all"
                                placeholder="http://localhost:5000"
                            />
                            <p className="text-xs text-slate-600 mt-1.5">EsaEmlak API Gateway adresi</p>
                        </div>
                    </div>
                    <button onClick={handleSave}
                        className="mt-5 flex items-center gap-2 px-5 py-2 rounded-xl bg-violet-600 hover:bg-violet-500 text-white text-sm font-medium transition-all">
                        <Save size={14} />
                        {saved ? 'Kaydedildi ✓' : 'Kaydet'}
                    </button>
                </div>

                {/* Info */}
                <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6">
                    <h2 className="text-base font-semibold text-white mb-4">Panel Bilgisi</h2>
                    <div className="space-y-3">
                        {[
                            ['Versiyon', '1.0.0'],
                            ['Framework', 'Next.js 14 (App Router)'],
                            ['Backend', '.NET 9 Microservices'],
                            ['Auth', 'JWT (HS256 — admin rolü)'],
                        ].map(([k, v]) => (
                            <div key={k} className="flex justify-between">
                                <span className="text-sm text-slate-500">{k}</span>
                                <span className="text-sm text-slate-300">{v}</span>
                            </div>
                        ))}
                    </div>
                </div>
            </div>
        </div>
    );
}
