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
    } else {

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
    }
  } catch (err) {
    console.error("Error seeding admin:", err.message);
  }

  // Seed demo pharmacist
  try {
    const pharmaEmail = "demo@pharmacy.com";
    const pharmaPassword = "demo123";

    let pharma = await User.findOne({ email: pharmaEmail });

    if (pharma) {
      console.log("Demo pharmacist already exists");
      return;
    }

    pharma = new User({
      name: "Demo Pharmacist",
      email: pharmaEmail,
      password: pharmaPassword,
      role: "pharmacist",
    });

    const salt = await bcrypt.genSalt(10);
    pharma.password = await bcrypt.hash(pharmaPassword, salt);

    await pharma.save();
    console.log("Demo pharmacist seeded successfully");
  } catch (err) {
    console.error("Error seeding pharmacist:", err.message);
  }
};

module.exports = seedAdmin;
