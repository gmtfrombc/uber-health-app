# QuickCarePT – UI Polishing Sprint (April 2025)

## What we shipped
1. **Home ➜ Services grid**  
   • Replaced CTA button with 3-col grid of service cards (light grey, 4 px gutters).  
   • Added PNG illustrations, `New` badge, dynamic provider routing.
2. **Bottom-nav**  
   • Added "My Health" tab; activity badge retained on Consults.
3. **Request Care flow**  
   • Context header (`Medical / Physical Therapy Services`) + icon, toggle hidden when forced.  
   • Provider selection button removed from Consults screen.
4. **My Health screen**  
   • Split mega-card into three surfaceVariant cards with coloured headers & chips.  
   • New page-level "Health Summary" headline, edit pencil retained.
5. **Coming Soon**  
   • Uses `ConsistentAppBar` styling.
6. **Theme & cleanup**  
   • Replaced deprecated `withOpacity` → `withValues`.  
   • Shared tile/card tint for visual consistency.

## Key decisions
• Follow Uber-style minimalism: light tiles, bold section headers, coloured icons.  
• Use `headlineSmall` / `titleLarge` for hierarchy; chips stay `bodyMedium`.  
• Service images delivered as 60 × 60 PNG, centre-fit; fallback to icon.  
• Card tint = `surfaceVariant` @ 0.4 (light) / 0.3 (dark).  
• Grid badges & headers update reactively via Provider.

## Open to-dos
- [ ] Replace remaining service icons with PNGs (Bereavement, Hospice, etc.).
- [ ] Review dark-mode contrast (green chips on dark grey).  
- [ ] Add tap haptics + scale animation to service tiles.  
- [ ] Accessibility labels for My Health chips.  
- [ ] Unit / widget tests for new UI states.  
- [ ] QA on Android tablets & web layouts.

---
Branch: `feature/ui-services-grid` – synced @ e3075a2 