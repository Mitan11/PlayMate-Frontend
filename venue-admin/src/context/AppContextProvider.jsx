import { createContext, useState } from "react"

export const AppContext = createContext()

const AppContextProvider = (props) => {
    const backendUrl = import.meta.env.VITE_BACKEND_URL;
    const [token, setToken] = useState(localStorage.getItem("token") ? localStorage.getItem("token") : false);
    const [venueOwner, setVenueOwner] = useState(localStorage.getItem("venue_owner") ? JSON.parse(localStorage.getItem("venue_owner")) : null);
    console.log("Venue Owner from context:", venueOwner);
    const value = {
        token, 
        setToken,
        venueOwner,
        setVenueOwner,
        backendUrl
    }

    return (
        <AppContext.Provider value={value}>
            {props.children}
        </AppContext.Provider>
    )
}

export default AppContextProvider   