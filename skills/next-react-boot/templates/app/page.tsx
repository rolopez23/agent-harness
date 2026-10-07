import BackendStatus from "@/components/BackendStatus";

export default function Home() {
  return (
    <main className="mx-auto flex min-h-screen max-w-2xl flex-col justify-center gap-6 px-6">
      <h1 className="text-4xl font-semibold tracking-tight">{{APP_NAME}}</h1>
      <p className="text-lg text-muted">
        {{APP_TAGLINE}}
      </p>
      <BackendStatus />
    </main>
  );
}
