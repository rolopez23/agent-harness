"use client";

import { useEffect, useState } from "react";
import { apiUrl } from "@/lib/api";

type Health = { status: string; database: string };

type State =
  | { kind: "checking" }
  | { kind: "reported"; health: Health }
  | { kind: "unreachable" };

function label(state: State): string {
  switch (state.kind) {
    case "checking":
      return "Checking…";
    case "reported":
      return `Backend: ${state.health.status} · Database: ${state.health.database}`;
    case "unreachable":
      return "Backend: unreachable";
  }
}

export default function BackendStatus() {
  const [state, setState] = useState<State>({ kind: "checking" });

  useEffect(() => {
    const controller = new AbortController();

    fetch(apiUrl("/api/health"), { signal: controller.signal, cache: "no-store" })
      .then(async (res) => {
        // 200 and 503 both carry a {status, database} body per the contract.
        if (res.ok || res.status === 503) {
          setState({ kind: "reported", health: (await res.json()) as Health });
        } else {
          setState({ kind: "unreachable" });
        }
      })
      .catch(() => {
        if (!controller.signal.aborted) setState({ kind: "unreachable" });
      });

    return () => controller.abort();
  }, []);

  return (
    <p role="status" className="font-mono text-sm text-muted">
      {label(state)}
    </p>
  );
}
