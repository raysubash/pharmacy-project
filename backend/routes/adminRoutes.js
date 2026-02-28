const express = require('express');
const router = express.Router();
const User = require('../models/User');
const PharmacyProfile = require('../models/PharmacyProfile');
const auth = require('../middleware/auth');
const bcrypt = require('bcryptjs');

// Admin Middleware - Check if user is admin
const adminAuth = async (req, res, next) => {
    try {
        const user = await User.findById(req.user.id);
        if (user.role !== 'admin') {
            return res.status(403).json({ message: 'Access denied. Admin only.' });
        }
        next();
    } catch (err) {
        res.status(500).json({ message: 'Server Error' });
    }
};

// Get all users with their subscription details
router.get('/users', auth, adminAuth, async (req, res) => {
    try {
        const users = await User.find({ role: { $ne: 'admin' } }).select('-password'); // Exclude admins from list if desired
        // Or include all users: const users = await User.find().select('-password');
        
        // Fetch profiles for each user to get subscription info
        const usersWithProfile = await Promise.all(users.map(async (user) => {
            const profile = await PharmacyProfile.findOne({ user: user._id });
            return {
                ...user.toObject(),
                profile: profile ? profile : null
            };
        }));

        res.json(usersWithProfile);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// Create User (Admin Action)
router.post('/users', auth, adminAuth, async (req, res) => {
    const { name, email, password, role } = req.body;
    try {
        let user = await User.findOne({ email });
        if (user) {
            return res.status(400).json({ message: 'User already exists' });
        }

        user = new User({
            name,
            email,
            password,
            role: role || 'pharmacist' // Default to pharmacist if created by admin
        });

        const salt = await bcrypt.genSalt(10);
        user.password = await bcrypt.hash(password, salt);

        await user.save();
        res.json(user);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// Delete User
router.delete('/users/:id', auth, adminAuth, async (req, res) => {
    try {
        // Remove user
        await User.findByIdAndDelete(req.params.id);
        // Remove associated profile
        await PharmacyProfile.findOneAndDelete({ user: req.params.id });
        
        res.json({ message: 'User deleted' });
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

module.exports = router;