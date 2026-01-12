import React from 'react'
import { motion } from 'framer-motion'
import { NavLink } from 'react-router'

function NavItem({ to, icon, text }) {
    return (
        <motion.li
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.95 }}
        >
            <NavLink
                className={({ isActive }) =>
                    `flex items-center gap-3 py-3.5 px-3 md:px-9 md:min-w-72 cursor-pointer ${isActive ? "bg-[#F2F3FF] border-r-4 border-primary" : ""
                    }`
                }
                to={to}
            >
                <img src={icon} alt={`${text} Icon`} />
                <p className='hidden md:block'>{text}</p>
            </NavLink>
        </motion.li>
    )
}

export default NavItem