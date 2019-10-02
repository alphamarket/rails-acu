User.delete_all
UserType.delete_all
# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
user_types_list = [
  [1, 'ادمین', 'ADMIN', 'ادمین سایت، دسترسی کامل به کل سایت' ,1001],
  [2, 'عموم', 'PUBLIC','دسترسی عمومی به محتویات سایت',1],
  [3, 'روکوب', 'ROKOB','موجودیت روکوب کار، امکان دسترسی به ارزیابی اطلاعات روکوبی مبلمان‌ها ',2],
  [4, 'خیاط', 'KHAYAT','موجودیت خیاط کار، امکان دسترسی به ارزیابی اطلاعات خیاطی مبلمان‌ها و مشخصات پارچه‌ ',2],
  [5, 'نجار', 'NAJAR','موجودیت نجار، امکان دسترسی به ارزیابی اطلاعات نجاری و کنده‌کاری مبلمان‌ها ',2],
  [6, 'نقاش', 'NAGASH','موجودیت نقاش کار، امکان دسترسی به ارزیابی اطلاعات نقاشی مبلمان‌ها ',2],
  [7, 'کارشناس گرافیک', 'GRAPHIC','بررسی گرافیکی و سلیقه‌ای محصولات و ثبت پیشنهادات مرتبط',2],
  [8, 'بازاریاب', 'MARKETER','بازاریاب‌ محصولات',2],
  [9, 'بازرس', 'PR','بازرسی کیفی فعالیت‌های بازاریاب‌ها، روابط عمومی مشتری‌ها',3],
  [10, 'بازارسنج', 'MARKLINE','مسئول بروز رسانی قیمت‌های کالاها و لوازم پیش‌نیاز محصولات خدماتی',2]
]

user_types_list.each do |id, name, symbol, comment, auth_level|
  UserType.create!(id: id, name: name, symbol: symbol, comment: comment, auth_level: auth_level)
end

users_list = [
  [1, 'email1@gmail.com','123456',1],
  [2, 'email2@gmail.com','123456',2],
  [3, 'email3@gmail.com','123456',3],
  [4, 'email4@gmail.com','123456',4],
  [5, 'email5@gmail.com','123456',5],
  [6, 'email6@gmail.com','123456',6],
  [7, 'email7@gmail.com','123456',7],
  [8, 'email8@gmail.com','123456',8],
  [9, 'email9@gmail.com','123456',9],
  [10, 'email10@gmail.com','123456',10],
]
users_list.each do |id, email, password, user_type_id|
  User.create!(id: id, email: email, password: password, user_type_id: user_type_id)
end