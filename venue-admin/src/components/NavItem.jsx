import React from 'react'
import { motion } from 'framer-motion'
import { NavLink } from 'react-router'
import Box from '@mui/joy/Box'
import Typography from '@mui/joy/Typography'

function NavItem({ to, icon, text, onClick, isMobile }) {
    return (
        <motion.li
            whileHover={{ x: 6 }}
            whileTap={{ scale: 0.98 }}
            style={{ listStyle: 'none' }}
        >
            <NavLink
                onClick={onClick}
                className={({ isActive }) =>
                    isActive ? 'nav-item-active' : 'nav-item'
                }
                to={to}
                style={({ isActive }) => ({
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: isMobile ? 'center' : 'flex-start',
                    gap: isMobile ? '0px' : '12px',
                    padding: isMobile ? '14px' : '16px',
                    marginLeft: '8px',
                    marginRight: '8px',

                    borderRadius: '12px',
                    cursor: 'pointer',
                    textDecoration: 'none',
                    color: isActive ? '#3b82f6' : '#6b7280',
                    backgroundColor: isActive ? 'rgba(59, 130, 246, 0.08)' : 'transparent',
                    borderLeft:
                        isActive && !isMobile
                            ? '3px solid #3b82f6'
                            : '3px solid transparent',

                    paddingLeft:
                        !isMobile
                            ? isActive ? '13px' : '16px'
                            : '14px',

                    transition: 'all 0.25s cubic-bezier(0.4, 0, 0.2, 1)',
                    position: 'relative',
                    overflow: 'hidden',
                    fontWeight: isActive ? 600 : 500,
                })}
            >
                <motion.div
                    whileHover={{ scale: 1.1 }}
                    transition={{ type: 'spring', stiffness: 300, damping: 20 }}
                >
                    <img
                        src={icon}
                        alt={`${text} Icon`}
                        style={{
                            width: '20px',
                            height: '20px',
                            opacity: 1,
                            filter: 'drop-shadow(0 1px 2px rgba(0,0,0,0.05))'
                        }}
                    />
                </motion.div>
                <Typography
                    level="body-sm"
                    sx={{
                        fontWeight: 600,
                        display: { xs: 'none', md: 'block' },
                        fontSize: { xs: '0.875rem', md: '0.9375rem' },
                        letterSpacing: '0.3px',
                    }}
                >
                    {text}
                </Typography>
            </NavLink>
        </motion.li>
    )
}

export default NavItem