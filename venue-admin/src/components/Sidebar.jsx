import React, { useContext, useState, useEffect } from "react";
import { motion } from "framer-motion";
import NavItem from "../components/NavItem";
import { AppContext } from "../context/AppContextProvider";
import { assets } from "../assets/assets";
import Box from "@mui/joy/Box";
import Tooltip from "@mui/joy/Tooltip";

function Sidebar() {
    const { token } = useContext(AppContext);
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
                                to="/dashboard"
                                icon={assets.home_icon}
                                text={isMobile ? "" : "Dashboard"}
                                isMobile={isMobile}
                            />
                        </div>
                    </Tooltip>
                </ul>
            </Box>
        </motion.aside>
    );
}

export default Sidebar;
