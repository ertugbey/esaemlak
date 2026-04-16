import { redirect } from 'next/navigation';

// Root redirects to dashboard; auth guard in (admin)/layout.tsx handles /login redirect
export default function RootPage() {
  redirect('/dashboard');
}
