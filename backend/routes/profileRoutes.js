const express = require("express");
const router = express.Router();
const PharmacyProfile = require("../models/PharmacyProfile");
const auth = require("../middleware/auth");

// Get profile
router.get("/", auth, async (req, res) => {
  try {
    const profile = await PharmacyProfile.findOne({ user: req.user.id });
    if (profile) {
      res.json(profile);
    } else {
      res.json(null); // Return null instead of 404 to indicate successful fetch but no profile
    }
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Create or Update profile
router.post("/", auth, async (req, res) => {
  try {
    // Check if profile exists
    let profile = await PharmacyProfile.findOne({ user: req.user.id });
    if (profile) {
      // Update
      // Ensure user ID is not overridden
      const updateData = { ...req.body, user: req.user.id };
      profile = await PharmacyProfile.findOneAndUpdate(
        { user: req.user.id },
        updateData,
        { returnDocument: "after" },
      );
      res.json(profile);
    } else {
      // Create
      const newProfile = new PharmacyProfile({
        ...req.body,
        user: req.user.id,
      });
      profile = await newProfile.save();
      res.json(profile);
    }
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
