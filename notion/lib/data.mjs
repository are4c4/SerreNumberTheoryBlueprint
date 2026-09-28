export async function getJson(path) {
  const separator = path.includes("?") ? "&" : "?";
  const response = await fetch(path + separator + "v=" + Date.now(), {cache:"no-store"});
  if (!response.ok) throw new Error(path + ": HTTP " + response.status);
  return response.json();
}

export async function getBuildVersion() {
  try {
    const value = await getJson("build-version.json");
    return value.commit || value.version || null;
  } catch {
    return null;
  }
}
