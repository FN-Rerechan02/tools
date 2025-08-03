#!/bin/sh

# =============================================
# Hapus swap lama jika ada
# =============================================
remove_old_swap() {
    # Nonaktifkan semua swap file
    swapoff -a >/dev/null 2>&1

    # Hapus entri swap lama dari fstab
    sed -i '/swap/d' /etc/fstab >/dev/null 2>&1
    sed -i '/\/swapfile/d' /etc/fstab >/dev/null 2>&1

    # Hapus file swap lama jika ada
    rm -f /swapfile >/dev/null 2>&1
    rm -f /swap.img >/dev/null 2>&1
}

# =============================================
# Buat Swapfile 4GB secara efisien
# =============================================
create_swap() {
    # Inisialisasi variabel metode
    METHOD="unknown"
    
    # Cari metode pembuatan file tercepat yang tersedia
    if command -v fallocate >/dev/null 2>&1; then
        fallocate -l 4G /swapfile >/dev/null 2>&1
        METHOD="fallocate"
    elif command -v dd >/dev/null 2>&1; then
        dd if=/dev/zero of=/swapfile bs=1M count=4096 >/dev/null 2>&1
        METHOD="dd"
    else
        # Metode alternatif menggunakan head
        head -c 4G /dev/zero > /swapfile 2>/dev/null
        METHOD="head"
    fi
    
    chmod 600 /swapfile
    mkswap /swapfile >/dev/null 2>&1
    
    # Simpan metode di variabel global
    SWAP_METHOD=$METHOD
}

# =============================================
# Stress test untuk memaksa swap bekerja
# =============================================
force_swap_usage() {
    echo "Forcing swap activation with stress-ng..."
    
    # Cek apakah stress-ng tersedia
    if ! command -v stress-ng >/dev/null 2>&1; then
        echo "stress-ng not found, installing..."
        apt-get update >/dev/null 2>&1
        apt-get install -y stress-ng >/dev/null 2>&1
    fi
    
    # Dapatkan jumlah CPU
    CPU_COUNT=$(nproc)
    
    # Jalankan stress test selama 5 detik:
    # - Menggunakan semua core CPU
    # - Mengalokasikan memori sebesar 1.5x RAM
    # - Menggunakan 128MB memori per worker
    MEM_PER_WORKER=128
    TOTAL_WORKERS=$(( ( $(free -m | awk '/Mem/{print $2}') * 3 / 2 ) / MEM_PER_WORKER ))
    
    echo "Running stress test with $TOTAL_WORKERS workers for 5 seconds..."
    stress-ng --vm $TOTAL_WORKERS --vm-bytes ${MEM_PER_WORKER}M --timeout 5s >/dev/null 2>&1
    
    # Tampilkan penggunaan swap setelah stress test
    echo "Swap usage after stress test:"
    free -h | awk '/Swap/{print "Used: "$3", Free: "$4}'
}

# =============================================
# Eksekusi utama (berjalan di background)
# =============================================
main() {
    # Hapus swap lama
    remove_old_swap
    
    # Buat swapfile baru
    create_swap
    
    # Aktifkan swap
    swapon /swapfile >/dev/null 2>&1
    
    # Pasang permanen
    grep -q "/swapfile" /etc/fstab || echo "/swapfile none swap defaults 0 0" >> /etc/fstab
    
    # Set swappiness ke 100 untuk penggunaan swap lebih agresif
    sysctl vm.swappiness=100 >/dev/null 2>&1
    grep -q "vm.swappiness" /etc/sysctl.conf || echo "vm.swappiness=100" >> /etc/sysctl.conf
    
    # Output minimal dengan informasi metode
    echo "Swap activated: $(free -h | awk '/Swap/{print $2}')"
    echo "Creation method: $SWAP_METHOD"
    echo "Swappiness set to: $(cat /proc/sys/vm/swappiness)"
    
    # Deteksi jenis file untuk verifikasi
    FILE_TYPE=$(file /swapfile)
    echo "Swap file type: $FILE_TYPE"
    
    # Paksa swap bekerja dengan stress test
    force_swap_usage
}

# Jalankan di background dengan output bersih
main >/dev/null 2>&1 &
