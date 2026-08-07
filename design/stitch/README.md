# Diseño Stitch — "Modern Inventory Manager" (StockFlow)

Referencia de diseño para implementar en Flutter. Design system: **"Precision Logic"**.
Proyecto Stitch ID: `4693282475210241556`.

> Traducción a Flutter es MANUAL: estos tokens y screenshots son el objetivo visual;
> se implementan como ThemeData + shared/ui (atomic design). Stitch NO genera Flutter.

## Design tokens

| Token | Valor |
|-------|-------|
| Primary | `#4F46E5` (indigo) — acciones y estados activos |
| Primary hover | indigo -10% |
| Texto | Deep Slate `#1E293B` (on-surface `#191c1e`) |
| Fondo (canvas) | `#F8FAFC` |
| Surface (cards) | `#FFFFFF` |
| Borde input | `#D1D5DB`; foco: indigo + glow 10% |
| Estados | Success verde · Warning ámbar · Danger rojo (pills) |
| Tipografía | **Inter** |
| display | 36/700, headline-lg 24/600, headline-md 20/600 |
| body-lg 16/400, body-md 14/400 (tablas), label-md 12/600 UPPER +0.05em |
| mono-sm 13/400 | para SKUs / IDs técnicos |
| Radios | sm .25rem, DEFAULT .5rem, **lg 1rem** (botones/inputs/cards), xl 1.5rem (modales), full (pills) |
| Espaciado | base 4px · sm 8 · md 16 (padding card) · lg 24 (entre secciones) · xl 32 |
| Sidebar | 280px fijo |
| Fila tabla | 56px de alto |
| Elevación L1 | `0 1px 3px rgba(0,0,0,.1), 0 1px 2px rgba(0,0,0,.06)` |

## Componentes
- **Botones**: Primary (indigo sólido, texto blanco) · Secondary (blanco + borde slate 1px) · Ghost (solo texto).
- **Tablas**: sticky header, zebra (blanco / `#F8FAFC`), borde inferior `#F1F5F9`, acciones icon-only.
- **Status pills**: Success/Warning/Danger, forma pill.
- **Inputs**: fondo blanco, borde `#D1D5DB`, foco indigo glow.
- **Cards**: blanco, `rounded-lg`, elevación L1, título `headline-md`.

## Pantallas (screen IDs)
| Pantalla | ID | Mapea a |
|----------|----|---------|
| Dashboard | `e4295926e3fd4f8f8d1a5ab99607b1f8` | overview + low-stock |
| Gestión de Stock (Inventory) | `a453945f799c43228d1612a9081e4d39` | products/variants |
| Movimientos | `bf6ed9629f714404bf41d558a4e99168` | stock movements |
| Configuración | `4fe14bdb33514b44b3d08d1deeca75f5` | settings |

Screenshots descargados: `dashboard.png`, `gestion-stock.png` (los otros se bajan al construir cada pantalla).
