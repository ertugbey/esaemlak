import { redirect } from 'next/navigation';
// This route (/) conflicts with app/page.tsx — redirect to /dashboard
export default function AdminRootPage() {
    redirect('/dashboard');
}
