-- ============================================================
-- SKEMA DATABASE - APLIKASI TOKO SEMBAKO
-- Jalankan file ini di Supabase SQL Editor (Project > SQL Editor > New query)
-- ============================================================

-- Ekstensi untuk UUID
create extension if not exists "uuid-ossp";

-- ------------------------------------------------------------
-- 1. PROFIL PENGGUNA (kasir / pemilik)
-- ------------------------------------------------------------
create table if not exists profiles (
    id uuid primary key references auth.users(id) on delete cascade,
    nama text not null,
    role text not null default 'kasir' check (role in ('owner', 'kasir')),
    created_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- 2. KATEGORI PRODUK
-- ------------------------------------------------------------
create table if not exists categories (
    id uuid primary key default uuid_generate_v4(),
    nama text not null unique,
    created_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- 3. PRODUK / BARANG
-- ------------------------------------------------------------
create table if not exists products (
    id uuid primary key default uuid_generate_v4(),
    nama_barang text not null,
    category_id uuid references categories(id) on delete set null,
    satuan text not null default 'pcs',       -- pcs, kg, liter, renteng, dus, dll
    harga_modal numeric(12,2) not null default 0,
    harga_jual numeric(12,2) not null default 0,
    harga_pack numeric(12,2),                 -- harga jual grosir/pack (opsional)
    stok numeric(12,2) not null default 0,
    stok_minimum numeric(12,2) not null default 5,
    barcode text,
    aktif boolean not null default true,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create index if not exists idx_products_nama on products using gin (to_tsvector('simple', nama_barang));
create index if not exists idx_products_category on products(category_id);

-- ------------------------------------------------------------
-- 3b. SUPPLIER / PABRIK / AGEN
-- ------------------------------------------------------------
create table if not exists suppliers (
    id uuid primary key default uuid_generate_v4(),
    nama text not null,
    kontak text,
    alamat text,
    catatan text,
    created_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- 3c. PEMBELIAN (belanja ke pabrik/pemasok)
-- ------------------------------------------------------------
create table if not exists purchases (
    id uuid primary key default uuid_generate_v4(),
    nomor_nota text,
    supplier_id uuid references suppliers(id) on delete set null,
    total numeric(12,2) not null default 0,
    status_bayar text not null default 'lunas' check (status_bayar in ('lunas', 'belum_lunas', 'sebagian')),
    jumlah_dibayar numeric(12,2) not null default 0,
    catatan text,
    dibuat_oleh uuid references profiles(id),
    created_at timestamptz not null default now()
);

create table if not exists purchase_items (
    id uuid primary key default uuid_generate_v4(),
    purchase_id uuid not null references purchases(id) on delete cascade,
    product_id uuid references products(id) on delete set null,
    nama_barang_snapshot text not null,
    harga_beli_satuan numeric(12,2) not null,
    jumlah numeric(12,2) not null,
    subtotal numeric(12,2) not null
);

-- TRIGGER: otomatis tambah stok & update harga modal saat ada pembelian
create or replace function fn_tambah_stok_pembelian()
returns trigger as $$
begin
    update products
    set stok = stok + new.jumlah,
        harga_modal = new.harga_beli_satuan,
        updated_at = now()
    where id = new.product_id;

    insert into stock_movements (product_id, tipe, jumlah, keterangan)
    values (new.product_id, 'masuk', new.jumlah, 'Pembelian ' || new.purchase_id);

    return new;
end;
$$ language plpgsql;

drop trigger if exists trg_tambah_stok_pembelian on purchase_items;
create trigger trg_tambah_stok_pembelian
after insert on purchase_items
for each row execute function fn_tambah_stok_pembelian();

-- ------------------------------------------------------------
-- 4. PERGERAKAN STOK (masuk/keluar/koreksi)
-- ------------------------------------------------------------
create table if not exists stock_movements (
    id uuid primary key default uuid_generate_v4(),
    product_id uuid not null references products(id) on delete cascade,
    tipe text not null check (tipe in ('masuk', 'keluar', 'koreksi')),
    jumlah numeric(12,2) not null,
    keterangan text,
    created_by uuid references profiles(id),
    created_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- 5. TRANSAKSI PENJUALAN
-- ------------------------------------------------------------
create table if not exists sales (
    id uuid primary key default uuid_generate_v4(),
    nomor_invoice text not null unique,
    total numeric(12,2) not null default 0,
    metode_bayar text not null default 'tunai' check (metode_bayar in ('tunai', 'qris', 'transfer', 'kasbon')),
    uang_diterima numeric(12,2),
    kembalian numeric(12,2),
    nama_pelanggan text,
    kasir_id uuid references profiles(id),
    created_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- 6. DETAIL ITEM TRANSAKSI
-- ------------------------------------------------------------
create table if not exists sale_items (
    id uuid primary key default uuid_generate_v4(),
    sale_id uuid not null references sales(id) on delete cascade,
    product_id uuid references products(id) on delete set null,
    nama_barang_snapshot text not null,   -- disimpan agar laporan lama tidak berubah walau nama produk diedit
    harga_satuan numeric(12,2) not null,
    jumlah numeric(12,2) not null,
    subtotal numeric(12,2) not null
);

-- ------------------------------------------------------------
-- TRIGGER: otomatis update stok saat ada transaksi penjualan
-- ------------------------------------------------------------
create or replace function fn_kurangi_stok()
returns trigger as $$
begin
    update products set stok = stok - new.jumlah, updated_at = now()
    where id = new.product_id;

    insert into stock_movements (product_id, tipe, jumlah, keterangan)
    values (new.product_id, 'keluar', new.jumlah, 'Penjualan ' || new.sale_id);

    return new;
end;
$$ language plpgsql;

drop trigger if exists trg_kurangi_stok on sale_items;
create trigger trg_kurangi_stok
after insert on sale_items
for each row execute function fn_kurangi_stok();

-- ------------------------------------------------------------
-- TRIGGER: updated_at otomatis
-- ------------------------------------------------------------
create or replace function fn_set_updated_at()
returns trigger as $$
begin
    new.updated_at = now();
    return new;
end;
$$ language plpgsql;

drop trigger if exists trg_products_updated_at on products;
create trigger trg_products_updated_at
before update on products
for each row execute function fn_set_updated_at();

-- ------------------------------------------------------------
-- ROW LEVEL SECURITY (RLS)
-- Semua pengguna yang login (anggota toko) boleh akses penuh.
-- Sesuaikan jika nanti ingin membedakan hak akses owner vs kasir.
-- ------------------------------------------------------------
alter table profiles enable row level security;
alter table categories enable row level security;
alter table products enable row level security;
alter table stock_movements enable row level security;
alter table sales enable row level security;
alter table sale_items enable row level security;
alter table suppliers enable row level security;
alter table purchases enable row level security;
alter table purchase_items enable row level security;

create policy "profiles_select_own" on profiles for select using (auth.uid() = id);
create policy "profiles_update_own" on profiles for update using (auth.uid() = id);

create policy "authenticated_full_access_categories" on categories
    for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

create policy "authenticated_full_access_products" on products
    for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

create policy "authenticated_full_access_stock_movements" on stock_movements
    for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

create policy "authenticated_full_access_sales" on sales
    for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

create policy "authenticated_full_access_sale_items" on sale_items
    for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

create policy "authenticated_full_access_suppliers" on suppliers
    for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

create policy "authenticated_full_access_purchases" on purchases
    for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

create policy "authenticated_full_access_purchase_items" on purchase_items
    for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

-- ------------------------------------------------------------
-- Otomatis buat baris profiles saat ada user baru daftar
-- ------------------------------------------------------------
create or replace function fn_handle_new_user()
returns trigger as $$
begin
    insert into public.profiles (id, nama, role)
    values (new.id, coalesce(new.raw_user_meta_data->>'nama', new.email), 'kasir');
    return new;
end;
$$ language plpgsql security definer;

drop trigger if exists trg_on_auth_user_created on auth.users;
create trigger trg_on_auth_user_created
after insert on auth.users
for each row execute function fn_handle_new_user();

-- ------------------------------------------------------------
-- KATEGORI AWAL (sesuai hasil kategorisasi data toko)
-- ------------------------------------------------------------
insert into categories (nama) values
    ('Sembako & Bumbu Dapur'),
    ('Minuman'),
    ('Perawatan & Kebersihan Diri'),
    ('Deterjen & Pembersih'),
    ('Obat & Kesehatan'),
    ('Alat & Perlengkapan Rumah'),
    ('Camilan & Mie Instan'),
    ('Rokok'),
    ('Lainnya')
on conflict (nama) do nothing;
