const DEFAULT_API_URL = "http://localhost:8000";

/** Backend base URL. Read at call time so Next can inline it and tests can override it. */
export function apiUrl(path: string): string {
  const base = process.env.NEXT_PUBLIC_API_URL || DEFAULT_API_URL;
  return `${base.replace(/\/$/, "")}${path}`;
}
