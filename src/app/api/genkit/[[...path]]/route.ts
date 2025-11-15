import { NextResponse } from 'next/server';

// Placeholder handler for the Genkit API route. The previous code used a
// helper from `@genkit-ai/next` that is not compatible with the installed
// package types. Expose simple GET/POST handlers that return 404 so the
// route exists and TypeScript knows the exported handlers.

export async function GET() {
	return NextResponse.json({ error: 'Not implemented' }, { status: 404 });
}

export async function POST() {
	return NextResponse.json({ error: 'Not implemented' }, { status: 404 });
}
