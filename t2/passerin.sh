#!/bin/bash

# مسیر فایل لاگ استخراج اطلاعات
auth_log="/var/log/auth.log"

# متغیری برای ذخیره آخرین مکان مشاهده‌شده در فایل لاگ
last_position=$(stat -c %s "$auth_log")

# تابعی برای استخراج اطلاعات PID، نام کاربری و پورت از رکوردهای لاگ Dropbear
extract_info() {
    log_entry=$1
    # استخراج اطلاعات PID، نام کاربری و پورت با استفاده از الگوهای جستجوی awk
    pid=$(echo "$log_entry" | awk -F'[][]' '{print $2}')
    username=$(echo "$log_entry" | awk -F"'" '{print $2}')
    port=$(echo "$log_entry" | awk -F'[: ]' '{print $NF}')
    echo "PID: $pid, Username: $username, Port: $port"
    # فراخوانی اسکریپت maker.sh و ارسال متغیرهای استخراج‌شده به عنوان آرگومان‌ها
    /root/t2/maker.sh "$pid" "$username" "$port"
}

# حلقه بی‌نهایت برای پایش فایل لاگ به صورت زنده
while true; do
    # به‌روزرسانی موقعیت جدید فایل لاگ
    new_position=$(stat -c %s "$auth_log")

    # اگر مکان جدید بزرگتر از مکان آخرین مشاهده‌شده باشد، اطلاعات جدید را استخراج می‌کنیم
    if [[ $new_position -gt $last_position ]]; then
        new_data=$(tail -c +$last_position "$auth_log")

        # خواندن خط به خط از اطلاعات جدید و جستجو برای رکوردهای مرتبط با dropbear و ورود موفق
        while IFS= read -r line; do
            if [[ $line == *"dropbear"* && $line == *"Password auth succeeded"* ]]; then
                extract_info "$line"
            fi
        done <<< "$new_data"

        # به‌روزرسانی مکان آخرین مشاهده‌شده با مکان جدید
        last_position=$new_position
    fi

    # تاخیر 1 ثانیه‌ای برای عملیات بعدی
    sleep 1
done
#!/bin/bash%s {   
