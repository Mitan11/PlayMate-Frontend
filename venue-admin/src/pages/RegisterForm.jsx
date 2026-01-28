import { useContext, useEffect, useState } from "react";
import { useNavigate } from "react-router";
import { AnimatePresence, motion } from "framer-motion";
import { FaEye, FaEyeSlash, FaArrowRight } from "react-icons/fa";
import { AppContext } from "../context/AppContextProvider";
import axios from "axios";
import { toast } from "react-hot-toast";

export default function RegisterForm() {
    const navigate = useNavigate();
    const { backendUrl, setToken, setVenueOwner } = useContext(AppContext);
    const [isLoading, setIsLoading] = useState(false);
    const [showPassword, setShowPassword] = useState(false);

    const [formData, setFormData] = useState({
        email: '',
        password: '',
        first_name: '',
        last_name: '',
        phone: ''
    });

    const [errors, setErrors] = useState({
        email: '',
        password: '',
        first_name: '',
        last_name: '',
        phone: ''
    });

    useEffect(() => {
        document.title = `PlayMate | Register`;
    }, []);

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
                [name]: ''
            }));
        }
    };

    const validateForm = () => {
        const newErrors = {};

        // First name validation
        if (!formData.first_name.trim()) {
            newErrors.first_name = 'First name is required';
        } else if (formData.first_name.trim().length < 2) {
            newErrors.first_name = 'First name must be at least 2 characters';
        }

        // Last name validation
        if (!formData.last_name.trim()) {
            newErrors.last_name = 'Last name is required';
        } else if (formData.last_name.trim().length < 2) {
            newErrors.last_name = 'Last name must be at least 2 characters';
        }

        // Email validation
        if (!formData.email.trim()) {
            newErrors.email = 'Email is required';
        } else if (!/\S+@\S+\.\S+/.test(formData.email)) {
            newErrors.email = 'Email is invalid';
        }

        // Phone validation
        if (!formData.phone.trim()) {
            newErrors.phone = 'Phone number is required';
        } else if (!/^[0-9]{10}$/.test(formData.phone.trim())) {
            newErrors.phone = 'Phone number must be 10 digits';
        }

        // Password validation
        if (!formData.password.trim()) {
            newErrors.password = 'Password is required';
        } else if (formData.password.trim().length < 8) {
            newErrors.password = 'Password must be at least 8 characters';
        }

        setErrors(newErrors);
        return Object.keys(newErrors).length === 0;
    };

    const handleSubmit = async (e) => {
        e.preventDefault();

        if (!validateForm()) {
            return;
        }

        setIsLoading(true);
        setShowPassword(false);

        try {
            const response = await axios.post(
                `${backendUrl}/venue/register`,
                {
                    email: formData.email.trim(),
                    password: formData.password.trim(),
                    first_name: formData.first_name.trim(),
                    last_name: formData.last_name.trim(),
                    phone: formData.phone.trim()
                }
            );

            if (response.data.status && (response.data.statusCode === 200 || response.data.statusCode === 201)) {
                const { token, venue } = response.data.data;

                // Auto-login the user
                if (token && venue) {
                    setToken(token);
                    setVenueOwner(venue);
                    localStorage.setItem("token", token);
                    localStorage.setItem("venue_owner", JSON.stringify(venue));

                    toast.success(response.data.message || 'Registration successful!');
                    navigate('/dashboard');
                } else {
                    toast.success(response.data.message || 'Registration successful! Please login.');
                    navigate('/login');
                }

                // Reset form
                setFormData({
                    email: '',
                    password: '',
                    first_name: '',
                    last_name: '',
                    phone: ''
                });
                setErrors({
                    email: '',
                    password: '',
                    first_name: '',
                    last_name: '',
                    phone: ''
                });
            } else {
                toast.error(response.data.message || 'Registration failed');
            }
        } catch (error) {
            console.log(error);

            // Handle field-specific errors
            if (error?.response?.data?.errors && Array.isArray(error.response.data.errors)) {
                const apiErrors = error.response.data.errors;
                const newErrors = {};

                apiErrors.forEach(err => {
                    // Map API field names to form field names
                    const fieldMapping = {
                        'venue_email': 'email',
                        'email': 'email',
                        'venue_phone': 'phone',
                        'phone': 'phone',
                        'venue_first_name': 'first_name',
                        'first_name': 'first_name',
                        'venue_last_name': 'last_name',
                        'last_name': 'last_name',
                        'venue_password': 'password',
                        'password': 'password'
                    };

                    const formField = fieldMapping[err.field] || err.field;
                    if (formData.hasOwnProperty(formField)) {
                        newErrors[formField] = err.message;
                    }
                });

                setErrors(prev => ({ ...prev, ...newErrors }));
            }

            const message =
                error?.response?.data?.message ||
                "Something went wrong. Please try again.";
            toast.error(message);
        } finally {
            setIsLoading(false);
        }
    };

    const containerVariants = {
        hidden: { opacity: 0, y: 20 },
        visible: {
            opacity: 1,
            y: 0,
            transition: {
                duration: 0.6,
                staggerChildren: 0.1,
                when: "beforeChildren",
            },
        },
    };

    const itemVariants = {
        hidden: { opacity: 0, y: 10 },
        visible: { opacity: 1, y: 0 },
    };

    const underlineVariants = {
        hidden: { width: 0 },
        visible: { width: "46%", transition: { duration: 0.9, ease: "easeInOut" } },
    };

    const stateChangeVariants = {
        initial: { y: 20, opacity: 0 },
        animate: { y: 0, opacity: 1 },
        exit: { y: -20, opacity: 0 },
    };

    return (
        <motion.form
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ duration: 0.5 }}
            className="min-h-[100vh] flex items-center justify-center"
            onSubmit={handleSubmit}
        >
            <motion.div
                initial={{ scale: 0.95, opacity: 0 }}
                animate={{ scale: 1, opacity: 1 }}
                transition={{ duration: 0.4 }}
                className="flex flex-col gap-4 m-auto items-start p-8 min-w-[300px] sm:min-w-96 border border-gray-300 rounded-xl text-zinc-600 text-sm shadow-lg bg-white"
            >
                <motion.div
                    className="w-full"
                    variants={containerVariants}
                    initial="hidden"
                    animate="visible"
                >
                    <motion.div variants={itemVariants}>
                        <AnimatePresence mode="wait">
                            <motion.h2
                                key="venue"
                                className="text-2xl font-semibold text-gray-800"
                                variants={stateChangeVariants}
                                initial="initial"
                                animate="animate"
                                exit="exit"
                                transition={{ duration: 0.3, ease: "easeInOut" }}
                            >
                                Venue Owner <span className="text-primary">Registration</span>
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

                <motion.div whileFocus={{ scale: 1.02 }} className="w-full">
                    <label htmlFor="first_name" className="block text-gray-700 mb-1 font-medium">
                        First Name
                    </label>
                    <motion.input
                        id="first_name"
                        name="first_name"
                        type="text"
                        value={formData.first_name}
                        onChange={handleChange}
                        placeholder="Enter your first name"
                        className={`w-full p-2 px-4 border focus:border-transparent ${errors.first_name ? "border-red-500" : "border-gray-300"
                            } rounded focus:outline-none focus:ring-2 focus:ring-indigo-600 transition duration-200 ${isLoading ? "cursor-not-allowed opacity-50" : ""
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
                        name="last_name"
                        type="text"
                        value={formData.last_name}
                        onChange={handleChange}
                        placeholder="Enter your last name"
                        className={`w-full p-2 px-4 border focus:border-transparent ${errors.last_name ? "border-red-500" : "border-gray-300"
                            } rounded focus:outline-none focus:ring-2 focus:ring-indigo-600 transition duration-200 ${isLoading ? "cursor-not-allowed opacity-50" : ""
                            }`}
                        disabled={isLoading}
                        whileFocus={{ scale: 1.02 }}
                    />
                    {errors.last_name && (
                        <p className="mt-1 text-sm text-red-500">{errors.last_name}</p>
                    )}
                </motion.div>

                <motion.div whileFocus={{ scale: 1.02 }} className="w-full">
                    <label htmlFor="email" className="block text-gray-700 mb-1 font-medium">
                        Email
                    </label>
                    <motion.input
                        id="email"
                        name="email"
                        type="email"
                        value={formData.email}
                        onChange={handleChange}
                        placeholder="Enter your email"
                        className={`w-full p-2 px-4 border focus:border-transparent ${errors.email ? "border-red-500" : "border-gray-300"
                            } rounded focus:outline-none focus:ring-2 focus:ring-indigo-600 transition duration-200 ${isLoading ? "cursor-not-allowed opacity-50" : ""
                            }`}
                        disabled={isLoading}
                        whileFocus={{ scale: 1.02 }}
                    />
                    {errors.email && (
                        <p className="mt-1 text-sm text-red-500">{errors.email}</p>
                    )}
                </motion.div>

                <motion.div whileFocus={{ scale: 1.02 }} className="w-full">
                    <label htmlFor="phone" className="block text-gray-700 mb-1 font-medium">
                        Phone Number
                    </label>
                    <motion.input
                        id="phone"
                        name="phone"
                        type="tel"
                        value={formData.phone}
                        onChange={handleChange}
                        placeholder="Enter 10-digit phone number"
                        className={`w-full p-2 px-4 border focus:border-transparent ${errors.phone ? "border-red-500" : "border-gray-300"
                            } rounded focus:outline-none focus:ring-2 focus:ring-indigo-600 transition duration-200 ${isLoading ? "cursor-not-allowed opacity-50" : ""
                            }`}
                        disabled={isLoading}
                        whileFocus={{ scale: 1.02 }}
                    />
                    {errors.phone && (
                        <p className="mt-1 text-sm text-red-500">{errors.phone}</p>
                    )}
                </motion.div>

                <motion.div whileFocus={{ scale: 1.02 }} className="w-full">
                    <label htmlFor="password" className="block text-gray-700 mb-1 font-medium">
                        Password
                    </label>
                    <div className="relative">
                        <motion.input
                            id="password"
                            name="password"
                            type={showPassword ? "text" : "password"}
                            value={formData.password}
                            onChange={handleChange}
                            placeholder="Enter password (min 8 characters)"
                            className={`w-full p-2 px-4 border focus:border-transparent ${errors.password ? "border-red-500" : "border-gray-300"
                                } rounded focus:outline-none focus:ring-2 focus:ring-indigo-600 transition duration-200 ${isLoading ? "cursor-not-allowed opacity-50" : ""
                                }`}
                            disabled={isLoading}
                            whileFocus={{ scale: 1.01 }}
                        />
                        {!isLoading && (
                            <motion.span
                                className="absolute right-3 top-1/2 -translate-y-1/2 cursor-pointer text-gray-400 hover:text-gray-600"
                                onClick={() => setShowPassword(!showPassword)}
                                whileHover={{ scale: 1.05 }}
                                whileTap={{ scale: 0.95 }}
                            >
                                {showPassword ? <FaEyeSlash /> : <FaEye />}
                            </motion.span>
                        )}
                    </div>
                    {errors.password && (
                        <p className="mt-1 text-sm text-red-500">{errors.password}</p>
                    )}
                </motion.div>

                <motion.button
                    type="submit"
                    disabled={isLoading}
                    className={`w-full py-3 font-medium flex items-center justify-center space-x-2 text-white bg-primary focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 rounded-md transition-all duration-200 ${isLoading ? "cursor-not-allowed opacity-50" : "cursor-pointer"
                        }`}
                    whileHover={{ scale: isLoading ? 1 : 1.02 }}
                    whileTap={{ scale: isLoading ? 1 : 0.98 }}
                >
                    {isLoading ? (
                        <>
                            <div className="w-5 h-5 border-t-2 border-r-2 border-white rounded-full animate-spin mr-2"></div>
                            <span>Registering...</span>
                        </>
                    ) : (
                        <>
                            <span>Create Account</span>
                            <FaArrowRight className="h-5 w-5 ml-2" />
                        </>
                    )}
                </motion.button>

                <motion.div
                    className="w-full text-center mt-2"
                    variants={itemVariants}
                >
                    <p className="text-sm text-gray-600">
                        Already have an account?{" "}
                        <motion.span
                            className="text-primary font-medium cursor-pointer hover:underline"
                            onClick={() => navigate("/login")}
                            whileHover={{ scale: 1.05 }}
                            whileTap={{ scale: 0.95 }}
                        >
                            Login here
                        </motion.span>
                    </p>
                </motion.div>

            </motion.div>
        </motion.form>
    );
}