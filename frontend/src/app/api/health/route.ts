import { NextResponse } from 'next/server';

export const dynamic = 'force-dynamic';

export async function GET() {
  const backendUrl = process.env.NEXT_PUBLIC_API_URL || 'https://school-management-production-596f.up.railway.app/api';
  try {
    const res = await fetch(`${backendUrl.replace(/\/$/, '')}/health`, {
      cache: 'no-store',
      headers: {
        'Accept': 'application/json',
      },
    });
    const data = await res.json();
    return NextResponse.json(data);
  } catch (error: any) {
    return NextResponse.json(
      {
        success: false,
        message: 'Could not connect to backend',
        backendUrl,
        error: error.message,
      },
      { status: 502 }
    );
  }
}
