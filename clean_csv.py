import csv

input_file = "data anggota.csv"
output_file = "data_anggota_clean.csv"

with open(input_file, 'r', encoding='utf-8') as infile, \
     open(output_file, 'w', encoding='utf-8', newline='') as outfile:
    
    reader = csv.reader(infile)
    writer = csv.writer(outfile)
    
    for row in reader:
        if len(row) == 1:
            # Jika baris cuma 1 kolom, coba split manual
            text = row[0]
            # Bersihkan tanda petik
            text = text.replace('""', '').replace('"', '')
            # Split berdasarkan koma
            parts = text.split(',')
            # Gabungkan kembali alamat yang terpisah
            if len(parts) >= 8:
                # Format: nik,nama,alamat,no_hp,total_simpanan,total_pinjaman,tanggal_daftar,status
                writer.writerow(parts)
            else:
                print(f"Skip: {row}")
        else:
            writer.writerow(row)

print("✅ CSV cleaned!")
