import React, { useState } from "react";
import { assets } from "../assets/assets";
import { useContext } from "react";
import { useNavigate } from "react-router";
import toast from "react-hot-toast";
import { motion } from "framer-motion";
import { AppContext } from "../context/AppContextProvider";
import Box from "@mui/joy/Box";
import Typography from "@mui/joy/Typography";
import IconButton from "@mui/joy/IconButton";
import Menu from "@mui/joy/Menu";
import MenuItem from "@mui/joy/MenuItem";
import Avatar from "@mui/joy/Avatar";
import Divider from "@mui/joy/Divider";

function Navbar() {
    const { aToken, setaToken } = useContext(AppContext);
    const navigate = useNavigate();
    const [anchorEl, setAnchorEl] = useState(null);

    const handleMenuToggle = (event) => {
        setAnchorEl((prev) => (prev ? null : event.currentTarget));
    };


    const logout = () => {
        if (aToken) {
            setaToken("");
            localStorage.removeItem("aToken");
            toast.success("Logout successful");
            setAnchorEl(null);
            navigate("/");
        }
    };

    return (
        <motion.div
            initial={{ opacity: 0, y: -20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.4 }}
        >
            <Box
                sx={{
                    display: "flex",
                    justifyContent: "space-between",
                    alignItems: "center",
                    px: { xs: 2, sm: 3, md: 4 },
                    py: { xs: 1.5, sm: 2 },
                    background: "linear-gradient(135deg, #ffffff 0%, #f8f9fa 100%)",
                    borderBottom: "1px solid",
                    borderColor: "rgba(0, 0, 0, 0.08)",
                    boxShadow: "0 1px 1px rgba(0,0,0,0.08)",
                    position: "sticky",
                    top: 0,
                    zIndex: 999,
                }}
            >
                {/* Left Section - Logo */}
                <Box
                    sx={{
                        display: "flex",
                        alignItems: "center",
                        gap: { xs: 1, sm: 2 },
                    }}
                >
                    <motion.img
                        whileHover={{ scale: 1.05 }}
                        className="cursor-pointer"
                        style={{ width: "auto", height: "55px", transition: "all 0.2s" }}
                        src={assets.icon}
                        alt="Admin Logo"
                    />
                    <Box sx={{ display: { xs: "none", sm: "block" } }}>
                        <Typography
                            level="h4"
                            sx={{
                                m: 0,
                                background: "linear-gradient(135deg, #3b82f6 0%, #2563eb 100%)",
                                WebkitBackgroundClip: "text",
                                WebkitTextFillColor: "transparent",
                                fontWeight: 700,
                                fontSize: { xs: "1rem", sm: "1.25rem" }
                            }}
                        >
                            <p className="border px-2.5 py-0.5 text-xs rounded-full border-gray-500 text-gray-600">
                                Admin
                            </p>
                        </Typography>
                    </Box>
                </Box>

                {/* Right Section - User Profile & Logout */}
                <Box
                    sx={{
                        display: "flex",
                        alignItems: "center",
                        gap: { xs: 1, sm: 2 },
                    }}
                >
                    <Box
                        sx={{
                            display: { xs: "none", sm: "flex" },
                            alignItems: "center",
                            gap: 1,
                            px: 2,
                            py: 1,
                            borderRadius: "12px",
                            backgroundColor: "rgba(59, 130, 246, 0.05)",
                        }}
                    >
                        <Avatar
                            size="sm"
                            variant="solid"
                            color="primary"
                            sx={{ fontSize: "0.875rem" }}
                        >
                            A
                        </Avatar>
                        <Box>
                            <Typography level="body-sm" sx={{ fontWeight: 600 }}>
                                Admin User
                            </Typography>
                            <Typography level="body-xs" sx={{ color: "neutral.400", fontSize: "0.75rem" }}>
                                Administrator
                            </Typography>
                        </Box>
                    </Box>

                    <Divider orientation="vertical" sx={{ display: { xs: "none", sm: "block" }, height: "24px", opacity: 0.3 }} />

                    <IconButton
                        size="sm"
                        variant="plain"
                        color="neutral"
                        onClick={handleMenuToggle}
                        sx={{
                            borderRadius: "10px",
                            transition: "all 0.2s",
                            "&:hover": {
                                backgroundColor: "rgba(59, 130, 246, 0.1)",
                            },
                        }}
                    >
                        <svg
                            xmlns="http://www.w3.org/2000/svg"
                            viewBox="0 0 24 24"
                            fill="currentColor"
                            width="20"
                            height="20"
                        >
                            <path d="M3 18h18v-2H3v2zm0-5h18v-2H3v2zm0-7v2h18V6H3z" />
                        </svg>
                    </IconButton>

                    <Menu
                        id="navbar-menu"
                        anchorEl={anchorEl}
                        open={Boolean(anchorEl)}
                        onClose={() => setAnchorEl(null)}
                        placement="bottom-end"
                        sx={{ zIndex: 1000 }}
                    >
                        <MenuItem
                            onClick={logout}
                            sx={{
                                display: "flex",
                                gap: 1.5,
                                px: 2,
                                py: 1.5,
                                fontWeight: 500,
                                color: "#dc2626",
                                transition: "all 0.2s",
                                "&:hover": {
                                    backgroundColor: "rgba(220, 38, 38, 0.08)",
                                }
                            }}
                        >
                            <svg
                                xmlns="http://www.w3.org/2000/svg"
                                viewBox="0 0 24 24"
                                fill="currentColor"
                                width="18"
                                height="18"
                            >
                                <path d="M17 7l-1.41 1.41L18.17 11H8v2h10.17l-2.58 2.58L17 17l5-5zM4 5h8V3H4c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h8v-2H4V5z" />
                            </svg>
                            Logout
                        </MenuItem>
                    </Menu>
                </Box>
            </Box>
        </motion.div>
    );
}

export default Navbar;
