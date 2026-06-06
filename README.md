# Otomatisasi Deployment Infrastruktur Dasar AWS Menggunakan Terraform

Repository ini berisi panduan laboratorium standar industri untuk melakukan provision (penyediaan) infrastruktur dasar di Amazon Web Services (AWS) menggunakan IaC (Infrastructure as Code) HashiCorp Terraform. Proyek ini membangun lingkungan yang terisolasi dan modular yang terdiri dari sebuah *compute node* EC2 Ubuntu 24.04 LTS, sebuah Elastic IP (EIP) untuk alamat publik statis, dan sebuah Amazon S3 bucket untuk penyimpanan objek.

---

## 🏗️ Ikhtisar Arsitektur

Infrastruktur yang dibangun melalui modul Terraform ini meliputi:
* **Compute (Komputasi):** 1x Amazon EC2 Instance dengan OS **Ubuntu 24.04 LTS (Noble Numbat)** yang dipilih secara dinamis menggunakan AMI data filtering.
* **Networking (Jaringan):** 1x AWS Elastic IP (EIP) yang dialokasikan dan dipetakan langsung ke instance EC2 untuk menjamin tersedianya IP publik statis.
* **Storage (Penyimpanan):** 1x Amazon S3 Bucket dengan nama global unik untuk penyimpanan objek atau aset statis.

---

## 🛠️ Prasyarat & Persiapan Lingkungan Kerja

Sebelum memulai proses inisialisasi, pastikan workstation Anda telah dikonfigurasi dengan *toolchain* dan kredensial yang tepat.

### Langkah 1: Persiapan Akun & IAM User AWS
1. Masuk ke **AWS Management Console** Anda (Gunakan AWS Free Tier jika baru memulai).
2. Buka layanan **IAM** -> **Users** -> **Create User**.
3. Berikan nama pengguna (contoh: `terraform-user`).
4. Pada bagian permissions, berikan akses: `AdministratorAccess` *(Catatan: Untuk lingkungan produksi, selalu terapkan prinsip hak akses seminim mungkin atau Principle of Least Privilege).*
5. Setelah user berhasil dibuat, buka tab **Security Credentials** dan pilih **Create Access Key**.
6. Simpan dua komponen rahasia berikut dengan aman:
   * `AWS_ACCESS_KEY_ID`
   * `AWS_SECRET_ACCESS_KEY`

### Langkah 2: Instalasi Terraform
Unduh binary Terraform resmi sesuai dengan sistem operasi Anda melalui [HashiCorp Downloads](https://developer.hashicorp.com/terraform/downloads). 

Untuk pengguna **Linux (Debian/Ubuntu)**, jalankan perintah berikut:
```bash
# Tambahkan GPG key resmi HashiCorp
wget -O- [https://apt.releases.hashicorp.com/gpg](https://apt.releases.hashicorp.com/gpg) | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

# Tambahkan repositori resmi HashiCorp
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] [https://apt.releases.hashicorp.com](https://apt.releases.hashicorp.com) $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

# Update indeks paket dan install Terraform
sudo apt update && sudo apt install terraform

# Verifikasi keberhasilan instalasi
terraform version

```

*Pastikan output menampilkan versi Terraform (contoh: `Terraform v1.12.x`).*

### Langkah 3: Konfigurasi AWS CLI

Pastikan AWS CLI sudah terinstall di perangkat Anda (`aws --version`). Lakukan pengikatan kredensial lokal ke akun AWS Anda dengan perintah:

```bash
aws configure

```

Masukkan parameter interaktif yang diminta:

* **AWS Access Key ID**: `[Masukkan Access Key Anda]`
* **AWS Secret Access Key**: `[Masukkan Secret Key Anda]`
* **Default region name**: `ap-southeast-1` (Singapura)
* **Default output format**: `json`

Verifikasi apakah konfigurasi lokal Anda sudah mengenali akun AWS tujuan dengan perintah:

```bash
aws sts get-caller-identity

```

---

## 📂 Struktur Direktori Proyek

Buat direktori kerja baru khusus untuk proyek ini. Struktur file yang digunakan mengikuti kaidah pemisahan peran (*separation of concerns*) standar Terraform:

```text
terraform-basic-infrastructure/
├── .gitignore          # Daftar file yang dikecualikan dari pelacakan Git
├── main.tf             # Blok utama arsitektur resource & provider AWS
├── variables.tf        # Definisi kontrak variabel input
├── terraform.tfvars    # Pengisian nilai variabel spesifik lingkungan
└── outputs.tf          # Telemetri data nilai output setelah deployment

```

Gunakan perintah berikut untuk membuat direktori:

```bash
mkdir -p terraform-basic-infrastructure
cd terraform-basic-infrastructure

```

---

## 📜 Blueprints Kode Konfigurasi

### 1. `variables.tf`

*Penjelasan: File ini bertindak sebagai skema deklarasi. Di sini kita menentukan variabel apa saja yang dibutuhkan oleh sistem beserta tipe datanya.*

```hcl
variable "aws_region" {
  description = "Region AWS target untuk deployment"
  type        = string
}

variable "instance_type" {
  description = "Tipe ukuran hardware untuk EC2 Instance"
  type        = string
}

variable "bucket_name" {
  description = "Nama unik global untuk alokasi Amazon S3 Bucket"
  type        = string
}

```

### 2. `terraform.tfvars`

*Penjelasan: File ini digunakan untuk menyuntikkan nilai asli ke dalam variabel yang didefinisikan sebelumnya. Nilai S3 Bucket harus diganti dengan nama unik Anda sendiri karena S3 bersifat global unique.*

```hcl
aws_region    = "ap-southeast-1"
instance_type = "t3.micro"
bucket_name   = "terraform-basic-bucket-namaanda-404"

```

### 3. `main.tf`

*Penjelasan: Ini adalah jantung dari infrastruktur kita. File ini mengatur provider, mencari AMI Ubuntu 24.04 LTS paling mutakhir secara otomatis lewat blok `data`, lalu mendefinisikan pembuatan resource EC2, Elastic IP, dan S3 Bucket.*

```hcl
terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

#################################################################################
# AWS PROVIDER CONFIGURATION
#################################################################################
provider "aws" {
  region = var.aws_region
}

#################################################################################
# DYNAMIC DATA SOURCE: UBUNTU 24.04 LTS AMI
#################################################################################
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # ID Akun Resmi Canonical (Pembuat Ubuntu)

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

#################################################################################
# RESOURCE DEFINITIONS
#################################################################################

# 1. Virtual Machine (EC2 Instance)
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  tags = {
    Name        = "Terraform-EC2"
    Environment = "Lab"
    Project     = "Terraform-Basic-Infrastructure"
  }
}

# 2. Networking (Elastic IP Assignment)
resource "aws_eip" "web_eip" {
  instance = aws_instance.web.id
  domain   = "vpc"

  tags = {
    Name        = "Terraform-EIP"
    Environment = "Lab"
    Project     = "Terraform-Basic-Infrastructure"
  }
}

# 3. Object Storage (S3 Bucket)
resource "aws_s3_bucket" "storage" {
  bucket        = var.bucket_name
  force_destroy = true # Memungkinkan penghapusan bucket bersih saat proses destroy

  tags = {
    Name        = "Terraform-Bucket"
    Environment = "Lab"
    Project     = "Terraform-Basic-Infrastructure"
  }
}

```

### 4. `outputs.tf`

*Penjelasan: Digunakan untuk menampilkan informasi penting ke layar terminal setelah proses deploy infrastruktur selesai.*

```hcl
output "ec2_public_ip" {
  description = "Alamat IP Publik Statis dari EC2 Instance"
  value       = aws_eip.web_eip.public_ip
}

output "s3_bucket_arn" {
  description = "Amazon Resource Name (ARN) dari S3 Bucket"
  value       = aws_s3_bucket.storage.arn
}

```

### 5. `.gitignore`

*Penjelasan: Sangat penting untuk mencegah berkas log lokal, file state yang sensitif, ataupun token akses terupload ke github publik.*

```text
.terraform/
*.tfstate
*.tfstate.backup
.terraform.lock.hcl
*.tfvars

```

---

## 🚀 Langkah-Langkah Eksekusi & Siklus Hidup Terraform

Ikuti instruksi berikut secara berurutan di dalam terminal direktori proyek Anda:

### Langkah 6: Inisialisasi Proyek (`terraform init`)

* **Penjelasan:** Perintah ini menganalisis file kode Anda, mengunduh plugin provider AWS yang diperlukan, dan menyiapkan direktori kerja lokal `.terraform/`.

```bash
terraform init

```

### Langkah 7: Validasi Kode (`terraform validate`)

* **Penjelasan:** Melakukan pengecekan internal apakah kode Terraform Anda memiliki kesalahan penulisan (*syntax error*) atau kesalahan struktural tanpa menyentuh cloud AWS.

```bash
terraform validate

```

### Langkah 8: Membuat Rencana Eksekusi (`terraform plan`)

* **Penjelasan:** Terraform akan mencocokkan kode Anda dengan kondisi real di AWS, lalu merancang perencanaan perubahan. Tanda `+` berarti resource baru akan dibuat.

```bash
terraform plan

```

### Langkah 9: Menerapkan Perubahan & Deploy (`terraform apply`)

* **Penjelasan:** Ini adalah langkah eksekusi nyata untuk membangun infrastruktur ke AWS.

```bash
terraform apply

```

*Saat muncul konfirmasi, ketik `yes` dan tekan **Enter**. Tunggu hingga proses pipeline selesai.*

### Langkah 10: Verifikasi Output Telemetri

Jika sukses, terminal akan memunculkan informasi ringkas dari file `outputs.tf`:

```text
Outputs:
ec2_public_ip = "54.255.xx.xx"
s3_bucket_arn = "arn:aws:s3:::terraform-basic-bucket-namaanda-404"

```

---

## 🔍 Langkah 11: Verifikasi Resource di AWS Console

Silakan masuk ke AWS Web Console Anda untuk memastikan semua resource berhasil dibuat:

1. **EC2 Dashboard -> Instances:** Pastikan ada instance bernama `Terraform-EC2` dengan status *Running*.
2. **EC2 Dashboard -> Elastic IPs:** Periksa alokasi IP publik statis baru yang terikat pada instance tersebut.
3. **S3 Dashboard:** Pastikan bucket dengan nama unik global Anda sudah terdaftar di sistem penyimpanan cloud.

---

## 🧠 Langkah 12 & 13: Memahami Konsep Terraform Local State

Setelah Anda melakukan `terraform apply`, sebuah file rahasia bernama `terraform.tfstate` akan tercipta secara otomatis di direktori Anda.

* **Mengapa ini penting?** File `.tfstate` adalah *Single Source of Truth* (Sumber Kebenaran Tunggal). File JSON ini mencatat relasi pasti antara kode `.tf` Anda dengan ID resource fisik asli yang ada di pusat data AWS.
* **Cara kerja:** Saat Anda melakukan modifikasi di kemudian hari, Terraform akan membandingkan: **Kode Anda (.tf)** 🆚 **State Real (.tfstate)** untuk menentukan apakah asset harus dibuat (*Create*), diperbarui (*Update*), atau dihancurkan (*Destroy*).

Untuk melihat daftar semua resource yang saat ini sedang dilacak di dalam file state, jalankan:

```bash
terraform state list

```

---

## 🛑 Langkah 14: Menghancurkan Infrastruktur (`terraform destroy`)

Untuk menghindari tagihan yang tidak diinginkan dari AWS (*cost-management*), Anda wajib membersihkan lingkungan laboratorium ini jika sudah selesai digunakan. Penghapusan seluruh infrastruktur dapat dilakukan secara otomatis lewat satu perintah:

```bash
terraform destroy

```

*Tinjau aset yang akan dihapus, ketik `yes` untuk memberikan konfirmasi final.*

---

## 📦 Langkah 15: Manajemen Kode & Push ke GitHub

Simpan hasil kerja profesional Anda ke dalam repositori GitHub Anda sebagai portofolio:

```bash
# Inisialisasi repositori Git lokal
git init

# Tambahkan semua file (file rahasia aman karena sudah ada .gitignore)
git add .

# Buat snapshot komitmen pertama dengan standardisasi pesan commit
git commit -m "feat: inisialisasi baseline infrastruktur dasar AWS menggunakan terraform"

# Hubungkan ke repository remote GitHub Anda
git remote add origin [https://github.com/username-anda/terraform-basic-infrastructure.git](https://github.com/username-anda/terraform-basic-infrastructure.git)
git branch -M main
git push -u origin main

```

```

```
