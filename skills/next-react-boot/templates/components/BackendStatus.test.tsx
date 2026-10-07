import { render, screen } from "@testing-library/react";
import { afterEach, describe, expect, it, vi } from "vitest";
import BackendStatus from "./BackendStatus";

function mockFetch(impl: () => Promise<Response>) {
  const fn = vi.fn(impl);
  vi.stubGlobal("fetch", fn);
  return fn;
}

function jsonResponse(status: number, body: unknown) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

afterEach(() => {
  vi.unstubAllGlobals();
  vi.unstubAllEnvs();
});

describe("BackendStatus", () => {
  it("shows a checking state while the request is in flight", () => {
    mockFetch(() => new Promise<Response>(() => {}));
    render(<BackendStatus />);
    expect(screen.getByText("Checking…")).toBeInTheDocument();
  });

  it("shows ok when backend and database are healthy", async () => {
    const fetchFn = mockFetch(async () => jsonResponse(200, { status: "ok", database: "ok" }));
    render(<BackendStatus />);
    expect(await screen.findByText("Backend: ok · Database: ok")).toBeInTheDocument();
    expect(fetchFn).toHaveBeenCalledWith("http://localhost:8000/api/health", expect.anything());
  });

  it("shows degraded when the backend returns 503", async () => {
    mockFetch(async () => jsonResponse(503, { status: "degraded", database: "unreachable" }));
    render(<BackendStatus />);
    expect(
      await screen.findByText("Backend: degraded · Database: unreachable"),
    ).toBeInTheDocument();
  });

  it("shows unreachable on a network error", async () => {
    mockFetch(async () => {
      throw new TypeError("Failed to fetch");
    });
    render(<BackendStatus />);
    expect(await screen.findByText("Backend: unreachable")).toBeInTheDocument();
  });

  it("uses NEXT_PUBLIC_API_URL when set", async () => {
    vi.stubEnv("NEXT_PUBLIC_API_URL", "http://api.example.test");
    const fetchFn = mockFetch(async () => jsonResponse(200, { status: "ok", database: "ok" }));
    render(<BackendStatus />);
    await screen.findByText("Backend: ok · Database: ok");
    expect(fetchFn).toHaveBeenCalledWith("http://api.example.test/api/health", expect.anything());
  });
});
