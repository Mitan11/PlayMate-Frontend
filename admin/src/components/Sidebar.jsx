import React, { useState, useEffect } from "react";
import { useSelector } from "react-redux";
import { motion } from "framer-motion";
import NavItem from "../components/NavItem";
import { assets } from "../assets/assets";
import Box from "@mui/joy/Box";
import Tooltip from "@mui/joy/Tooltip";
import { selectAuthToken } from "../features/auth/authSelectors";

function Sidebar() {
    const token = useSelector(selectAuthToken);
    const [isMobile, setIsMobile] = useState(window.innerWidth < 768);

    useEffect(() => {
        const handleResize = () => {
            setIsMobile(window.innerWidth < 900);
        };
        window.addEventListener("resize", handleResize);
        return () => window.removeEventListener("resize", handleResize);
    }, []);

    if (!token) return null;

    return (
        <motion.aside
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ duration: 0.3 }}
            style={{
                width: isMobile ? 64 : 240,
                minHeight: "calc(100vh - 60px)",
                background: "linear-gradient(180deg, #ffffff 0%, #f8f9fa 100%)",
                borderRight: "1px solid rgba(0,0,0,0.06)",
                display: "flex",
                flexDirection: "column",
            }}
        >
            <Box sx={{ py: 2 }}>
                <ul style={{ listStyle: "none", padding: 0, margin: 0 }}>
                    <Tooltip title="Dashboard" placement="right" disableHoverListener={!isMobile}>
                        <div>
                            <NavItem
                                to="/admin-dashboard"
                                icon={assets.home_icon}
                                text={isMobile ? "" : "Dashboard"}
                                centerIcon={isMobile}
                            />
                        </div>
                    </Tooltip>

                    <Tooltip title="Sports Management" placement="right" disableHoverListener={!isMobile}>
                        <div>
                            <NavItem
                                to="/sports-management"
                                icon={assets.sports_icon}
                                text={isMobile ? "" : "Sports Management"}
                                centerIcon={isMobile}
                            />
                        </div>
                    </Tooltip>

                    <Tooltip title="Users Management" placement="right" disableHoverListener={!isMobile}>
                        <div>
                            <NavItem
                                to="/users-management"
                                icon={assets.users_icon}
                                text={isMobile ? "" : "Users Management"}
                                centerIcon={isMobile}
                            />
                        </div>
                    </Tooltip>
                    <Tooltip title="Venue Management" placement="right" disableHoverListener={!isMobile}>
                        <div>
                            <NavItem
                                to="/venue-management"
                                icon={assets.venue_icon}
                                text={isMobile ? "" : "Venue Management"}
                                centerIcon={isMobile}
                            />
                        </div>
                    </Tooltip>
                    <Tooltip title="Posts Management" placement="right" disableHoverListener={!isMobile}>
                        <div>
                            <NavItem
                                to="/posts-management"
                                icon={assets.posts_icon}
                                text={isMobile ? "" : "Posts Management"}
                                centerIcon={isMobile}
                            />
                        </div>
                    </Tooltip>
                </ul>
            </Box>
        </motion.aside>
    );
}

export default Sidebar;
