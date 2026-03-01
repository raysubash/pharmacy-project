const mongoose = require("mongoose");
const bcrypt = require("bcryptjs");
const User = require("./models/User");

const seedAdmin = async () => {
  try {
    const adminEmail = "adminsubash@gmail.com";
    const adminPassword = "adminsubash";

    let admin = await User.findOne({ email: adminEmail });

    if (admin) {
      console.log("Admin user already exists");
      return;
    }

    admin = new User({
      name: "Super Admin",
      email: adminEmail,
      password: adminPassword,
      role: "admin",
    });

    const salt = await bcrypt.genSalt(10);
    admin.password = await bcrypt.hash(adminPassword, salt);

    await admin.save();
    console.log("Admin user seeded successfully");
  } catch (err) {
    console.error("Error seeding admin:", err.message);
  }
};

module.exports = seedAdmin;
