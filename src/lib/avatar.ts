/**
 * Initials avatar for users with no uploaded profile picture.
 *
 * Returned as an inline SVG data URI so it needs no network request and cannot
 * itself fail to load - which matters, because it is used as an <img> onError
 * fallback and a failing fallback would re-fire onError forever.
 *
 * The colour is derived from the name, so a given person always gets the same
 * one and a list of users looks varied rather than uniform.
 */

const hueFromName = (name: string): number => {
  let h = 0;
  for (let i = 0; i < name.length; i++) {
    h = (h * 31 + name.charCodeAt(i)) % 360;
  }
  return h;
};

export const initialsAvatar = (firstName?: string, lastName?: string): string => {
  const name = `${firstName ?? ""} ${lastName ?? ""}`.trim();
  const initials =
    ((firstName?.trim()[0] ?? "") + (lastName?.trim()[0] ?? "")).toUpperCase() || "?";
  const hue = hueFromName(name || initials);

  const svg =
    `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128">` +
    `<rect width="128" height="128" fill="hsl(${hue},30%,24%)"/>` +
    `<text x="64" y="64" text-anchor="middle" dominant-baseline="central" ` +
    `font-family="Inter,system-ui,-apple-system,sans-serif" font-size="52" font-weight="500" ` +
    `fill="hsl(${hue},42%,78%)">${initials}</text>` +
    `</svg>`;

  return `data:image/svg+xml,${encodeURIComponent(svg)}`;
};

/** onError handler that swaps in the initials avatar exactly once. */
export const avatarFallback =
  (firstName?: string, lastName?: string) =>
    (e: React.SyntheticEvent<HTMLImageElement>) => {
      const img = e.currentTarget;
      img.onerror = null;
      img.src = initialsAvatar(firstName, lastName);
    };
