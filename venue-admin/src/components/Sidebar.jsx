import React, { useContext } from "react";
import { motion } from "framer-motion";
import NavItem from "../components/NavItem";
import { AppContext } from "../context/AppContextProvider";
import { assets } from "../assets/assets";

function Sidebar() {
    const { aToken } = useContext(AppContext);

    // Sidebar Animation Variants
    const sidebarVariants = {
        hidden: { x: -250, opacity: 0 }, // Initially hidden (off-screen)
        visible: {
            x: 0,
            opacity: 1,
            transition: { duration: 0.5, ease: "easeOut" },
        }, // Animate in
    };

    return (
        <motion.div
            className="min-h-screen bg-white border-r border-gray-300"
            variants={sidebarVariants}
            initial="hidden"
            animate="visible"
        >
            <ul className="text-[#515151] mt-5">
                <NavItem
                    to="/admin-dashboard"
                    icon={assets.home_icon}
                    text="Dashboard"
                />
            </ul>
        </motion.div>
    );
}

export default Sidebar;
