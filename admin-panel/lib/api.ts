// All requests go through Next.js server-side proxy at /api/proxy/[...path]
// This avoids CORS issues when browser calls backend services directly
const PROXY = '/api/proxy';

function getHeaders(token?: string) {
    const h: Record<string, string> = { 'Content-Type': 'application/json' };
    if (token) h['Authorization'] = `Bearer ${token}`;
    return h;
}

// ─── AUTH ────────────────────────────────────────────────────────────────────

export async function loginAdmin(email: string, password: string) {
    const res = await fetch(`${PROXY}/api/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password }),
    });
    if (!res.ok) throw new Error('Giriş başarısız');
    return res.json();
}

// ─── ADMIN: USERS ─────────────────────────────────────────────────────────────

export async function getAdminUsers(token: string, params: Record<string, string | number> = {}) {
    const qs = new URLSearchParams(params as Record<string, string>).toString();
    const res = await fetch(`${PROXY}/api/auth/admin/users?${qs}`, { headers: getHeaders(token) });
    if (!res.ok) throw new Error('Users fetch failed');
    return res.json();
}

export async function getAdminUserStats(token: string) {
    const res = await fetch(`${PROXY}/api/auth/admin/stats`, { headers: getHeaders(token) });
    if (!res.ok) throw new Error('Stats fetch failed');
    return res.json();
}

export async function banUser(token: string, id: string) {
    const res = await fetch(`${PROXY}/api/auth/admin/users/${id}/ban`, {
        method: 'PATCH',
        headers: getHeaders(token),
    });
    if (!res.ok) throw new Error('Ban failed');
    return res.json();
}

export async function updateUserRol(token: string, id: string, rol: string) {
    const res = await fetch(`${PROXY}/api/auth/admin/users/${id}/rol`, {
        method: 'PATCH',
        headers: getHeaders(token),
        body: JSON.stringify({ rol }),
    });
    if (!res.ok) throw new Error('Rol update failed');
    return res.json();
}

export async function createAdminUser(token: string, data: {
    ad: string; soyad: string; email: string; telefon: string;
    password: string; rol: string; onayli: boolean;
}) {
    const res = await fetch(`${PROXY}/api/auth/admin/users`, {
        method: 'POST',
        headers: getHeaders(token),
        body: JSON.stringify(data),
    });
    if (!res.ok) { const e = await res.json(); throw new Error(e.error || 'Create failed'); }
    return res.json();
}

export async function updateAdminUser(token: string, id: string, data: {
    ad?: string; soyad?: string; email?: string; telefon?: string;
    rol?: string; onayli?: boolean; password?: string;
}) {
    const res = await fetch(`${PROXY}/api/auth/admin/users/${id}`, {
        method: 'PUT',
        headers: getHeaders(token),
        body: JSON.stringify(data),
    });
    if (!res.ok) { const e = await res.json(); throw new Error(e.error || 'Update failed'); }
    return res.json();
}

export async function deleteAdminUser(token: string, id: string) {
    const res = await fetch(`${PROXY}/api/auth/admin/users/${id}`, {
        method: 'DELETE',
        headers: getHeaders(token),
    });
    if (!res.ok) throw new Error('Delete failed');
    return res.json();
}

// ─── ADMIN: LISTINGS ─────────────────────────────────────────────────────────

export async function getAdminListings(token: string, params: Record<string, string | number | boolean> = {}) {
    const qs = new URLSearchParams(Object.fromEntries(
        Object.entries(params).filter(([, v]) => v !== undefined && v !== null && v !== '').map(([k, v]) => [k, String(v)])
    )).toString();
    const res = await fetch(`${PROXY}/api/listings/admin/all?${qs}`, { headers: getHeaders(token) });
    if (!res.ok) throw new Error('Listings fetch failed');
    return res.json();
}

export async function getAdminListingStats(token: string) {
    const res = await fetch(`${PROXY}/api/listings/admin/stats`, { headers: getHeaders(token) });
    if (!res.ok) throw new Error('Listing stats failed');
    return res.json();
}

export async function getPendingListings(token: string, params: Record<string, string | number> = {}) {
    const qs = new URLSearchParams(params as Record<string, string>).toString();
    const res = await fetch(`${PROXY}/api/listings/admin/pending?${qs}`, { headers: getHeaders(token) });
    if (!res.ok) throw new Error('Pending listings fetch failed');
    return res.json();
}

export async function approveListing(token: string, id: string) {
    const res = await fetch(`${PROXY}/api/listings/admin/${id}/approve`, {
        method: 'PATCH',
        headers: getHeaders(token),
    });
    if (!res.ok) throw new Error('Approve failed');
    return res.json();
}

export async function rejectListing(token: string, id: string) {
    const res = await fetch(`${PROXY}/api/listings/admin/${id}/reject`, {
        method: 'PATCH',
        headers: getHeaders(token),
    });
    if (!res.ok) throw new Error('Reject failed');
    return res.json();
}

export async function adminDeleteListing(token: string, id: string) {
    const res = await fetch(`${PROXY}/api/listings/admin/${id}`, {
        method: 'DELETE',
        headers: getHeaders(token),
    });
    if (!res.ok) throw new Error('Delete failed');
    return res.json();
}

// ─── ADMIN: MESSAGES ─────────────────────────────────────────────────────────

export async function getAdminMessages(token: string, params: Record<string, string | number> = {}) {
    const qs = new URLSearchParams(params as Record<string, string>).toString();
    const res = await fetch(`${PROXY}/api/messages/admin/all?${qs}`, { headers: getHeaders(token) });
    if (!res.ok) return { messages: [], total: 0 }; // graceful if not implemented
    return res.json();
}

// ─── ADMIN: PAYMENTS ─────────────────────────────────────────────────────────

export async function getAdminPayments(token: string, params: Record<string, string | number> = {}) {
    const qs = new URLSearchParams(params as Record<string, string>).toString();
    const res = await fetch(`${PROXY}/api/payments/admin/all?${qs}`, { headers: getHeaders(token) });
    if (!res.ok) return { payments: [], total: 0 }; // graceful if not implemented
    return res.json();
}
