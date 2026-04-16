import { NextRequest, NextResponse } from 'next/server';

const API_GATEWAY_URL = process.env.API_GATEWAY_URL || 'http://localhost:5000';

export const dynamic = 'force-dynamic';

async function handler(req: NextRequest, { params }: { params: Promise<{ path: string[] }> }) {
    const { path } = await params;
    
    const targetPath = '/' + path.join('/');
    const targetUrl = `${API_GATEWAY_URL}${targetPath}${req.nextUrl.search}`;

    console.log(`[PROXY] ${req.method} ${targetPath} → ${targetUrl}`);

    // Build headers
    const headers: Record<string, string> = {};
    const contentType = req.headers.get('content-type');
    if (contentType) headers['content-type'] = contentType;

    const auth = req.headers.get('authorization');
    if (auth) headers['authorization'] = auth;

    // Read body for non-GET requests
    let body: string | undefined;
    if (req.method !== 'GET' && req.method !== 'HEAD') {
        body = await req.text();
    }

    try {
        const upstream = await fetch(targetUrl, {
            method: req.method,
            headers,
            body,
        });

        const responseText = await upstream.text();
        console.log(`[PROXY] Response: ${upstream.status} from ${targetUrl}`);

        return new NextResponse(responseText, {
            status: upstream.status,
            headers: {
                'content-type': upstream.headers.get('content-type') || 'application/json',
            },
        });
    } catch (error) {
        console.error('[PROXY] Error:', error);
        return NextResponse.json(
            { error: 'Upstream service unavailable', detail: String(error) },
            { status: 503 }
        );
    }
}

export { handler as GET, handler as POST, handler as PUT, handler as PATCH, handler as DELETE };
