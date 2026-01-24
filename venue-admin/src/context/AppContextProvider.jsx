import axios from "axios";
import { createContext, useState } from "react"

export const AppContext = createContext()

const AppContextProvider = (props) => {
    const backendUrl = import.meta.env.VITE_BACKEND_URL;
    const [token, setToken] = useState(localStorage.getItem("token") ? localStorage.getItem("token") : false);
    const [venueOwner, setVenueOwner] = useState(localStorage.getItem("venue_owner") ? JSON.parse(localStorage.getItem("venue_owner")) : null);
    console.log("Venue Owner from context:", venueOwner);

    const getVenueSpots = async (setSports, setLoading) => {
        setLoading(true);
        try {
            const response = await axios.get(
                `${backendUrl}/venue/sports/${venueOwner.venue_id}`,
                {
                    headers: {
                        Authorization: `Bearer ${token}`
                    }
                }
            );

            if (response.data.status && response.data.data) {
                setSports(response.data.data);
            }
            setLoading(false);
        } catch (error) {
            console.error('Error fetching venue sports:', error);
            setLoading(false);
        }
    }

    const value = {
        token,
        setToken,
        venueOwner,
        setVenueOwner,
        backendUrl,
        getVenueSpots
    }

    return (
        <AppContext.Provider value={value}>
            {props.children}
        </AppContext.Provider>
    )
}

export default AppContextProvider   