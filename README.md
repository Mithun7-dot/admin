# Mithun Rocks — Admin Panel

A Flutter Web admin dashboard for the **Mithun Rocks** e-commerce platform.  
Built with Flutter, Supabase, GoRouter, and Riverpod.

---

## 🚀 Running the App

```bash
cd admin
flutter run -d chrome --web-port 8081
```

- Admin Panel → http://localhost:8081  
- Consumer App → `cd mithun_rocks && flutter run -d chrome --web-port 8082`

---

## 🗂️ Project Structure

```
admin/
├── lib/
│   ├── main.dart                        # App entry point
│   ├── core/
│   │   └── constants.dart               # Supabase URL & anon key
│   ├── infrastructure/
│   │   ├── router.dart                  # All routes + auth guard
│   │   └── theme.dart                   # Design system (colors, fonts, widgets)
│   ├── layouts/
│   │   └── admin_layout.dart            # Sidebar, page header, stat card widgets
│   └── screens/
│       ├── login_screen.dart            # Admin login (role-gated)
│       ├── dashboard_screen.dart        # Stats overview + recent orders
│       ├── products_screen.dart         # Product CRUD + image upload
│       ├── orders_screen.dart           # Order management + status updates
│       ├── categories_screen.dart       # Category CRUD
│       ├── banners_screen.dart          # Home banner management
│       ├── users_screen.dart            # User list + role management
│       └── coupons_screen.dart          # Coupon/discount code CRUD
├── pubspec.yaml                         # Dependencies
└── README.md                            # This file
```

---

## 🔐 Authentication & Access Control

**File:** `lib/screens/login_screen.dart`  
**Route:** `/login`

- Uses Supabase `signInWithPassword` to authenticate.
- After login, checks the `users` table for `role == 'admin'`.
- If the user is NOT an admin, it signs them out and shows "Access denied."
- On success, navigates to `/dashboard`.

**File:** `lib/infrastructure/router.dart`

- Every route (except `/login`) is guarded by a `redirect` function.
- The redirect checks for an active Supabase session AND verifies `role == 'admin'` in the `users` table.
- If either check fails, the user is sent to `/login`.

---

## 🧭 Routing

**File:** `lib/infrastructure/router.dart`

Uses **GoRouter** with a `ShellRoute` so all authenticated pages share the sidebar layout.

| Route | Screen |
|---|---|
| `/login` | `AdminLoginScreen` |
| `/dashboard` | `DashboardScreen` |
| `/products` | `ProductsScreen` |
| `/orders` | `AdminOrdersScreen` |
| `/categories` | `CategoriesScreen` |
| `/banners` | `BannersScreen` |
| `/users` | `UsersScreen` |
| `/coupons` | `CouponsScreen` |

- The `adminRouterProvider` is a Riverpod `Provider<GoRouter>`.
- All protected routes are children of a `ShellRoute` that wraps them with `AdminLayout`.

---

## 🎨 Design System

**File:** `lib/infrastructure/theme.dart`

### Color Palette (`AdminColors`)

| Token | Hex | Usage |
|---|---|---|
| `bg` | `#0A0A0A` | Page background |
| `surface` | `#131313` | Cards, dialogs |
| `surfaceHigh` | `#1C1B1B` | Input fills, dropdowns |
| `card` | `#1A1A1A` | Table containers |
| `border` | `#2A2A2A` | All borders/dividers |
| `accent` | `#E8C547` | Gold — CTAs, active states |
| `success` | `#4CAF50` | Active/delivered status |
| `warning` | `#FF9800` | Pending status |
| `error` | `#EF5350` | Delete, cancelled, errors |
| `info` | `#2196F3` | Confirmed status |
| `textMuted` | `#919191` | Labels, table headers |

### Typography
- **Headings:** `Epilogue` (Google Fonts) — bold, uppercase, strong weight
- **Body/Labels:** `Manrope` (Google Fonts) — clean, readable

### `AdminTheme.darkTheme`
A complete Material 3 `ThemeData` configured with:
- Dark color scheme with `accent` as primary
- Styled `ElevatedButton`, `OutlinedButton`, `InputDecoration`, `Card`, `Dialog`, `SnackBar`

---

## 🏗️ Layout System

**File:** `lib/layouts/admin_layout.dart`

### `AdminLayout`
Responsive wrapper — uses a permanent sidebar on screens > 900px wide, and a drawer on mobile.

### `_Sidebar`
- Fixed 240px wide navigation panel.
- Nav items: Dashboard, Products, Orders, Categories, Banners, Users, Coupons.
- Active route highlighted with a gold left border (`AdminColors.accent`).
- **Sign Out** button at the bottom calls `Supabase.auth.signOut()` then redirects to `/login`.

### `AdminPageHeader` (shared widget)
Used at the top of every screen. Shows:
- Page title (large, white, Epilogue font)
- Optional subtitle (e.g. item count)
- Optional action button (e.g. "ADD PRODUCT")

### `AdminStatCard` (shared widget)
Used on the Dashboard. Shows:
- A label, large value, icon, and optional change/hint text.
- Icon background uses the card's color at 12% opacity.

---

## 📊 Features

---

### 1. Dashboard
**File:** `lib/screens/dashboard_screen.dart`  
**Route:** `/dashboard`

**How it works:**
- Fires 6 parallel Supabase queries using `Future.wait([...])` to load all stats at once without waiting one by one.
- Calculates **Total Revenue** by summing the `total` column of all `payment_status == 'paid'` orders.
- Stats shown: Total Revenue, Total Orders, Products, Customers.
- Below the stats, shows the **8 most recent orders** in a table with order number, customer email, status badge, total, and date.
- Uses `FutureBuilder` for async data — shows a loader while fetching.
- The stats grid adapts: 4 columns on wide screens, 2 on medium, 1 on narrow.

**Supabase tables used:** `orders`, `products`, `users`

---

### 2. Products
**File:** `lib/screens/products_screen.dart`  
**Route:** `/products`

**How it works:**
- Fetches all products with their category name joined: `.select('*, categories(name)')`.
- Displays products in a styled table with: thumbnail, name, SKU, category, price, stock, active toggle, edit/delete actions.
- **Active Toggle:** Calls `_toggleActive()` which does a PATCH to `is_active` on the `products` table.
- **Delete:** Shows a confirmation dialog before deleting.

**Add/Edit Product dialog (`_ProductDialog`):**
- Fields: Name, Price, Compare Price, Stock, SKU, Category (dropdown), Description.
- **Images section** (dual input):
  - **"Upload File" button:** Opens `FilePicker` to pick an image from the local device → uploads binary to Supabase Storage bucket `products` → gets the public URL → appends to `_imageUrls` list.
  - **URL input field:** Paste any external image URL → press Enter or the `+` icon → appends to `_imageUrls` list.
  - Image previews shown as 90×90 thumbnails. First image is labelled "MAIN". Each has an `×` button to remove it.
- On save, the `images` array (list of URLs) is written to the `products.images` column.

**Supabase tables used:** `products`, `categories`  
**Supabase Storage bucket used:** `products` (public, 5MB limit, images only)

---

### 3. Orders
**File:** `lib/screens/orders_screen.dart`  
**Route:** `/orders`

**How it works:**
- Fetches all orders joined with the customer's email and name: `.select('*, users(email, full_name)')`.
- **Filter bar:** Chips at the top for All, Pending, Confirmed, Processing, Shipped, Delivered, Cancelled. Clicking a chip re-fetches with `.eq('status', filter)`.
- Each row shows: order number, customer email, total, status badge (colour-coded), date, and a **status update dropdown**.
- Changing the dropdown calls `_updateStatus()` which does a PATCH to `orders.status` immediately.

**Status colours:**
- Pending → Orange, Confirmed → Blue, Processing → Purple,  
  Shipped → Cyan, Delivered → Green, Cancelled/Refunded → Red

**Supabase tables used:** `orders`, `users`

---

### 4. Categories
**File:** `lib/screens/categories_screen.dart`  
**Route:** `/categories`

**How it works:**
- Fetches categories ordered by `sort_order` column.
- Displays as a responsive grid of cards (max 280px wide each).
- Each card shows: icon, name, sort order, edit and delete buttons.
- **Add/Edit dialog (`_CatDialog`):** Fields: Name, Slug (auto-generated from name if left empty), Description, Sort Order, Active checkbox.
- Slug is auto-generated by lowercasing the name and replacing spaces with `-`.

**Supabase tables used:** `categories`

---

### 5. Banners
**File:** `lib/screens/banners_screen.dart`  
**Route:** `/banners`

**How it works:**
- Fetches banners ordered by `sort_order`.
- Displayed as a vertical list. Each row shows: image preview (120×70), title, subtitle, sort order, active toggle, edit/delete buttons.
- Image is loaded from the `image_url` field using `Image.network`.
- **Add/Edit dialog (`_BannerDialog`):** Fields: Title, Subtitle, Image URL, Action URL (deep link or page route when tapped), Sort Order, Active.

> **Note:** Banners currently use URL-only for images. Local upload can be added similarly to Products.

**Supabase tables used:** `banners`

---

### 6. Users
**File:** `lib/screens/users_screen.dart`  
**Route:** `/users`

**How it works:**
- Fetches all users ordered by `created_at` descending (newest first).
- Displays in a table: avatar (first letter of name), full name, email, phone, role badge, join date, and a role action button.
- **Role management:**
  - If user is `customer` → shows "Make Admin" button (gold).
  - If user is `admin` → shows "Revoke Admin" button (red).
  - Clicking either updates `users.role` via Supabase PATCH and shows a SnackBar confirmation.

**Supabase tables used:** `users`

---

### 7. Coupons
**File:** `lib/screens/coupons_screen.dart`  
**Route:** `/coupons`

**How it works:**
- Fetches coupons ordered by `created_at` descending.
- Table shows: code (styled like a ticket), discount type badge, value, minimum order, usage count/limit, active toggle, edit/delete.
- **Add/Edit dialog (`_CouponDialog`):** Fields: Code (auto-uppercased), Description, Discount Type (Percentage % or Flat ₹), Discount Value, Min Order Amount, Max Discount cap, Usage Limit, Active.
- Toggle switch directly patches `is_active` on change.

**Supabase tables used:** `coupons`

---

## 🗄️ Supabase Database Tables

| Table | Used By |
|---|---|
| `users` | Login (role check), Users screen, Dashboard |
| `products` | Products screen, Dashboard |
| `categories` | Categories screen, Products dialog |
| `orders` | Orders screen, Dashboard |
| `order_items` | (Available — not yet shown in admin) |
| `banners` | Banners screen |
| `coupons` | Coupons screen |

**Storage Bucket:** `products` — public bucket for product images uploaded from the admin panel.

---

## 📦 Dependencies

| Package | Purpose |
|---|---|
| `supabase_flutter` | Database, Auth, Storage |
| `go_router` | Declarative routing with auth redirect |
| `flutter_riverpod` | State management (router provider) |
| `google_fonts` | Epilogue + Manrope fonts |
| `file_picker` | Local file picking for image upload |
| `cached_network_image` | Efficient network image loading |
| `fl_chart` | (Available for future chart widgets) |
| `data_table_2` | (Available for advanced tables) |

---

## ✏️ How to Add a New Screen

1. Create `lib/screens/my_screen.dart` with a `StatefulWidget`.
2. Add a route in `lib/infrastructure/router.dart` inside the `ShellRoute.routes` list.
3. Add a `_NavItem` entry in `_Sidebar._items` in `lib/layouts/admin_layout.dart`.
4. Use `AdminPageHeader` at the top and follow the existing screen patterns.

---

## 🔑 Environment / Config

**File:** `lib/core/constants.dart`

```dart
class AppConstants {
  static const String supabaseUrl = 'https://dpvvgioytyfhigrnsdyo.supabase.co';
  static const String supabaseAnonKey = '...';
}
```

> The anon key is safe to include in a Flutter Web app — Supabase RLS policies on the database control data access.

---
