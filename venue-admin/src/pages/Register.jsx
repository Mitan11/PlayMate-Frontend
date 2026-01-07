import React, { useState } from 'react'
import { AnimatePresence, motion } from "framer-motion";
import { FaArrowRight, FaEye, FaEyeSlash } from "react-icons/fa";
import { Link } from 'react-router';

function Register() {
    const [formData, setFormData] = useState({
        first_name: "",
        last_name: "",
        email: "",
        phone: "",
        password: "",
        confirm_password: ""
    });
    const [showPassword, setShowPassword] = useState(false);
    const [showConfirmPassword, setShowConfirmPassword] = useState(false);
    const [errors, setErrors] = useState({
        first_name: "",
        last_name: "",
        email: "",
        phone: "",
        password: "",
        confirm_password: ""
    });
    const [isLoading, setIsLoading] = useState(false);

    // Animation variants
    const containerVariants = {
        hidden: { opacity: 0 },
        visible: {
            opacity: 1,
            transition: {
                staggerChildren: 0.1
            }
        }
    };

    const itemVariants = {
        hidden: { opacity: 0, y: 20 },
        visible: {
            opacity: 1,
            y: 0,
            transition: { duration: 0.5 }
        }
    };

    const stateChangeVariants = {
        initial: { opacity: 0, y: -10 },
        animate: { opacity: 1, y: 0 },
        exit: { opacity: 0, y: 10 }
    };

    const underlineVariants = {
        hidden: { width: 0 },
        visible: {
            width: "146px",
            transition: { duration: 0.5, delay: 0.2 }
        }
    };

    const handleChange = (e) => {
        const { name, value } = e.target;
        setFormData(prev => ({
            ...prev,
            [name]: value
        }));
        // Clear error when user starts typing
        if (errors[name]) {
            setErrors(prev => ({
                ...prev,
                [name]: ""
            }));
        }
    };

    const validateForm = () => {
        let isValid = true;
        const newErrors = {
            first_name: "",
            last_name: "",
            email: "",
            phone: "",
            password: "",
            confirm_password: ""
        };

        // First name validation
        if (!formData.first_name.trim()) {
            newErrors.first_name = "First name is required";
            isValid = false;
        }

        // Last name validation
        if (!formData.last_name.trim()) {
            newErrors.last_name = "Last name is required";
            isValid = false;
        }

        // Email validation
        if (!formData.email.trim()) {
            newErrors.email = "Email is required";
            isValid = false;
        } else if (!/\S+@\S+\.\S+/.test(formData.email)) {
            newErrors.email = "Please enter a valid email";
            isValid = false;
        }

        // Phone validation
        if (!formData.phone.trim()) {
            newErrors.phone = "Phone number is required";
            isValid = false;
        } else if (!/^\d{10}$/.test(formData.phone.replace(/\D/g, ''))) {
            newErrors.phone = "Please enter a valid 10-digit phone number";
            isValid = false;
        }

        // Password validation
        if (!formData.password.trim()) {
            newErrors.password = "Password is required";
            isValid = false;
        } else if (formData.password.length < 6) {
            newErrors.password = "Password must be at least 6 characters";
            isValid = false;
        }

        // Confirm password validation
        if (!formData.confirm_password.trim()) {
            newErrors.confirm_password = "Please confirm your password";
            isValid = false;
        } else if (formData.password !== formData.confirm_password) {
            newErrors.confirm_password = "Passwords do not match";
            isValid = false;
        }

        setErrors(newErrors);
        return isValid;
    };

    const onSubmitHandler = (e) => {
        e.preventDefault();

        if (!validateForm()) {
            return;
        }

        setIsLoading(true);

        // Simulate API call
        setTimeout(() => {
            console.log('Registration submitted:', formData);
            setIsLoading(false);
            // Here you would typically handle the registration logic
            // navigate('/login');
        }, 1500);
    };

    return (
        <motion.form
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ duration: 0.5 }}
            className="min-h-[100vh] flex items-center justify-center py-8"
            onSubmit={onSubmitHandler}
        >
            <motion.div
                initial={{ scale: 0.95, opacity: 0 }}
                animate={{ scale: 1, opacity: 1 }}
                transition={{ duration: 0.4 }}
                className="flex flex-col gap-4 m-auto items-start p-8 min-w-[300px] sm:min-w-96 border border-gray-300 rounded-xl text-zinc-600 text-sm shadow-lg bg-white"
            >
                <motion.div
                    className="w-full mb-4"
                    variants={containerVariants}
                    initial="hidden"
                    animate="visible"
                >
                    <motion.div variants={itemVariants}>
                        <AnimatePresence mode="wait">
                            <motion.h2
                                key="venue-owner-register"
                                className="text-2xl font-semibold text-gray-800"
                                variants={stateChangeVariants}
                                initial="initial"
                                animate="animate"
                                exit="exit"
                                transition={{ duration: 0.3, ease: "easeInOut" }}
                            >
                                Venue Owner <span className="text-primary">Register</span>
                            </motion.h2>
                        </AnimatePresence>
                    </motion.div>
                    <motion.div
                        className="h-1 bg-primary mt-1 rounded"
                        variants={underlineVariants}
                        initial="hidden"
                        animate="visible"
                    />
                </motion.div>

                {/* First Name and Last Name Row */}
                <div className="w-full grid grid-cols-1 sm:grid-cols-2 gap-4">
                    <motion.div whileFocus={{ scale: 1.02 }} className="w-full">
                        <label htmlFor="first_name" className="block text-gray-700 mb-1 font-medium">
                            First Name
                        </label>
                        <motion.input
                            id="first_name"
                            type="text"
                            name="first_name"
                            value={formData.first_name}
                            onChange={handleChange}
                            placeholder="Enter first name"
                            className={`w-full p-2 px-4 border focus:border-transparent ${errors.first_name ? "border-red-500" : "border-gray-300"
                                } rounded focus:outline-none focus:ring-2 focus:ring-primary transition duration-200 ${isLoading ? "cursor-not-allowed opacity-50" : ""
                                }`}
                            disabled={isLoading}
                            whileFocus={{ scale: 1.02 }}
                        />
                        {errors.first_name && (
                            <p className="mt-1 text-sm text-red-500">{errors.first_name}</p>
                        )}
                    </motion.div>

                    <motion.div whileFocus={{ scale: 1.02 }} className="w-full">
                        <label htmlFor="last_name" className="block text-gray-700 mb-1 font-medium">
                            Last Name
                        </label>
                        <motion.input
                            id="last_name"
                            type="text"
                            name="last_name"
                            value={formData.last_name}
                            onChange={handleChange}
                            placeholder="Enter last name"
                            className={`w-full p-2 px-4 border focus:border-transparent ${errors.last_name ? "border-red-500" : "border-gray-300"
                                } rounded focus:outline-none focus:ring-2 focus:ring-primary transition duration-200 ${isLoading ? "cursor-not-allowed opacity-50" : ""
                                }`}
                            disabled={isLoading}
                            whileFocus={{ scale: 1.02 }}
                        />
                        {errors.last_name && (
                            <p className="mt-1 text-sm text-red-500">{errors.last_name}</p>
                        )}
                    </motion.div>
                </div>

                {/* Email Field */}
                <motion.div whileFocus={{ scale: 1.02 }} className="w-full">
                    <label htmlFor="email" className="block text-gray-700 mb-1 font-medium">
                        Email
                    </label>
                    <motion.input
                        id="email"
                        type="email"
                        name="email"
                        value={formData.email}
                        onChange={handleChange}
                        placeholder="Enter your email"
                        className={`w-full p-2 px-4 border focus:border-transparent ${errors.email ? "border-red-500" : "border-gray-300"
                            } rounded focus:outline-none focus:ring-2 focus:ring-primary transition duration-200 ${isLoading ? "cursor-not-allowed opacity-50" : ""
                            }`}
                        disabled={isLoading}
                        whileFocus={{ scale: 1.02 }}
                    />
                    {errors.email && (
                        <p className="mt-1 text-sm text-red-500">{errors.email}</p>
                    )}
                </motion.div>

                {/* Phone Field */}
                <motion.div whileFocus={{ scale: 1.02 }} className="w-full">
                    <label htmlFor="phone" className="block text-gray-700 mb-1 font-medium">
                        Phone
                    </label>
                    <motion.input
                        id="phone"
                        type="tel"
                        name="phone"
                        value={formData.phone}
                        onChange={handleChange}
                        placeholder="Enter phone number"
                        className={`w-full p-2 px-4 border focus:border-transparent ${errors.phone ? "border-red-500" : "border-gray-300"
                            } rounded focus:outline-none focus:ring-2 focus:ring-primary transition duration-200 ${isLoading ? "cursor-not-allowed opacity-50" : ""
                            }`}
                        disabled={isLoading}
                        whileFocus={{ scale: 1.02 }}
                    />
                    {errors.phone && (
                        <p className="mt-1 text-sm text-red-500">{errors.phone}</p>
                    )}
                </motion.div>

                {/* Password Field */}
                <motion.div whileFocus={{ scale: 1.02 }} className="w-full">
                    <label htmlFor="password" className="block text-gray-700 mb-1 font-medium">
                        Password
                    </label>
                    <div className="relative">
                        <motion.input
                            id="password"
                            type={showPassword ? "text" : "password"}
                            name="password"
                            value={formData.password}
                            onChange={handleChange}
                            placeholder="Enter your password"
                            className={`w-full p-2 px-4 border focus:border-transparent ${errors.password ? "border-red-500" : "border-gray-300"
                                } rounded focus:outline-none focus:ring-2 focus:ring-primary transition duration-200 ${isLoading ? "cursor-not-allowed opacity-50" : ""
                                }`}
                            disabled={isLoading}
                            whileFocus={{ scale: 1.01 }}
                        />
                        <motion.span
                            className="absolute right-3 top-1/2 -translate-y-1/2 cursor-pointer text-gray-400 hover:text-gray-600"
                            onClick={() => setShowPassword(!showPassword)}
                            whileHover={{ scale: 1.05 }}
                            whileTap={{ scale: 0.95 }}
                        >
                            {showPassword ? <FaEyeSlash /> : <FaEye />}
                        </motion.span>
                    </div>
                    {errors.password && (
                        <p className="mt-1 text-sm text-red-500">{errors.password}</p>
                    )}
                </motion.div>

                {/* Confirm Password Field */}
                <motion.div whileFocus={{ scale: 1.02 }} className="w-full">
                    <label htmlFor="confirm_password" className="block text-gray-700 mb-1 font-medium">
                        Confirm Password
                    </label>
                    <div className="relative">
                        <motion.input
                            id="confirm_password"
                            type={showConfirmPassword ? "text" : "password"}
                            name="confirm_password"
                            value={formData.confirm_password}
                            onChange={handleChange}
                            placeholder="Confirm your password"
                            className={`w-full p-2 px-4 border focus:border-transparent ${errors.confirm_password ? "border-red-500" : "border-gray-300"
                                } rounded focus:outline-none focus:ring-2 focus:ring-primary transition duration-200 ${isLoading ? "cursor-not-allowed opacity-50" : ""
                                }`}
                            disabled={isLoading}
                            whileFocus={{ scale: 1.01 }}
                        />
                        <motion.span
                            className="absolute right-3 top-1/2 -translate-y-1/2 cursor-pointer text-gray-400 hover:text-gray-600"
                            onClick={() => setShowConfirmPassword(!showConfirmPassword)}
                            whileHover={{ scale: 1.05 }}
                            whileTap={{ scale: 0.95 }}
                        >
                            {showConfirmPassword ? <FaEyeSlash /> : <FaEye />}
                        </motion.span>
                    </div>
                    {errors.confirm_password && (
                        <p className="mt-1 text-sm text-red-500">{errors.confirm_password}</p>
                    )}
                </motion.div>

                {/* Submit Button */}
                <motion.button
                    type="submit"
                    disabled={isLoading}
                    className={`w-full py-3 font-medium flex items-center justify-center space-x-2 text-white bg-primary focus:outline-none focus:ring-2 focus:ring-primary focus:ring-offset-2 rounded-md transition-all duration-200 ${isLoading ? "cursor-not-allowed opacity-50" : "cursor-pointer hover:bg-primary/90"
                        }`}
                    whileHover={{ scale: isLoading ? 1 : 1.02 }}
                    whileTap={{ scale: isLoading ? 1 : 0.98 }}
                >
                    {isLoading ? (
                        <>
                            <div className="w-5 h-5 border-t-2 border-r-2 border-white rounded-full animate-spin mr-2"></div>
                            <span>Creating Account...</span>
                        </>
                    ) : (
                        <>
                            <span>Create Account</span>
                            <FaArrowRight className="h-5 w-5 ml-2" />
                        </>
                    )}
                </motion.button>

                {/* Login Link */}
                <motion.div className="w-full text-center" variants={itemVariants}>
                    <p className="text-sm text-gray-600">
                        Already have an account?{" "}
                        <Link to="/" className="text-primary underline cursor-pointer hover:text-primary/80">
                            Login here
                        </Link>
                    </p>
                </motion.div>
            </motion.div>
        </motion.form>
    );
}

export default Register;