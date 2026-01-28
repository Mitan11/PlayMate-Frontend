import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import Box from '@mui/joy/Box';
import Button from '@mui/joy/Button';
import Table from '@mui/joy/Table';
import Sheet from '@mui/joy/Sheet';
import Skeleton from '@mui/joy/Skeleton';
import Typography from '@mui/joy/Typography';
import Input from '@mui/joy/Input';
import Link from '@mui/joy/Link';
import ArrowDownwardIcon from '@mui/icons-material/ArrowDownward';

function DataTable({
    columns,
    rows,
    actions = [],
    loading = false,
    skeletonRows = 5,
    firstColumnWidth = 80,
    lastColumnWidth = 144,
    searchable = true,
    searchPlaceholder = "Search...",
    pageSize = 7,
    debounceDelay = 300,
    throttleDelay = 100,
    defaultSort = { key: "no", direction: 'asc' },
}) {
    const [searchQuery, setSearchQuery] = useState('');
    const [debouncedSearchQuery, setDebouncedSearchQuery] = useState('');
    const [sortConfig, setSortConfig] = useState(defaultSort);
    const [page, setPage] = useState(1);
    const debounceTimeoutRef = useRef(null);
    const throttleTimeoutRef = useRef(null);
    const lastThrottleTime = useRef(0);

    // Debounce function
    const debounce = useCallback((func, delay) => {
        return (...args) => {
            clearTimeout(debounceTimeoutRef.current);
            debounceTimeoutRef.current = setTimeout(() => func(...args), delay);
        };
    }, []);

    // Throttle function
    const throttle = useCallback((func, delay) => {
        return (...args) => {
            const now = Date.now();
            if (now - lastThrottleTime.current >= delay) {
                lastThrottleTime.current = now;
                func(...args);
            } else if (!throttleTimeoutRef.current) {
                throttleTimeoutRef.current = setTimeout(() => {
                    lastThrottleTime.current = Date.now();
                    func(...args);
                    throttleTimeoutRef.current = null;
                }, delay - (now - lastThrottleTime.current));
            }
        };
    }, []);

    // Debounced search handler
    const debouncedSetSearchQuery = useCallback(
        debounce((query) => {
            setDebouncedSearchQuery(query);
        }, debounceDelay),
        [debounce, debounceDelay]
    );

    // Handle search input change
    const handleSearchChange = useCallback((e) => {
        const value = e.target.value;
        setSearchQuery(value);
        debouncedSetSearchQuery(value);
    }, [debouncedSetSearchQuery]);

    // Filter rows based on debounced search query
    const filteredRows = useMemo(() => {
        if (!debouncedSearchQuery) return rows;

        return rows.filter((row) =>
            columns.some((col) =>
                String(row[col.key] ?? '')
                    .toLowerCase()
                    .includes(debouncedSearchQuery.toLowerCase())
            )
        );
    }, [rows, debouncedSearchQuery, columns]);

    // Sort filtered rows
    const sortedRows = useMemo(() => {
        if (!sortConfig) return filteredRows;

        const { key, direction } = sortConfig;

        return [...filteredRows].sort((a, b) => {
            const aVal = a[key];
            const bVal = b[key];

            if (aVal == null) return 1;
            if (bVal == null) return -1;

            if (typeof aVal === 'number' && typeof bVal === 'number') {
                return direction === 'asc' ? aVal - bVal : bVal - aVal;
            }

            return direction === 'asc'
                ? String(aVal).localeCompare(String(bVal))
                : String(bVal).localeCompare(String(aVal));
        });

    }, [filteredRows, sortConfig]);

    // Paginate sorted rows
    const paginatedRows = useMemo(() => {
        const start = (page - 1) * pageSize;
        return sortedRows.slice(start, start + pageSize);
    }, [sortedRows, page, pageSize]);

    // Calculate total pages
    const totalPages = Math.ceil(sortedRows.length / pageSize);

    // Reset page when debounced search or sort changes
    useEffect(() => {
        setPage(1);
    }, [debouncedSearchQuery, sortConfig]);

    // Cleanup timeouts on unmount
    useEffect(() => {
        return () => {
            if (debounceTimeoutRef.current) {
                clearTimeout(debounceTimeoutRef.current);
            }
            if (throttleTimeoutRef.current) {
                clearTimeout(throttleTimeoutRef.current);
            }
        };
    }, []);


    return (
        <Box sx={{ width: '100%' }}>
            {/* Search Input */}
            {searchable && (
                <Box sx={{ mb: 2 }}>
                    <Input
                        placeholder={searchPlaceholder}
                        value={searchQuery}
                        onChange={handleSearchChange}
                        sx={{ width: '100%' }}
                    />
                </Box>
            )}

            <Sheet
                variant="outlined"
                sx={(theme) => ({
                    '--TableCell-height': '40px',
                    '--TableHeader-height': 'calc(1 * var(--TableCell-height))',
                    '--Table-firstColumnWidth': `${firstColumnWidth}px`,
                    '--Table-lastColumnWidth': `${lastColumnWidth}px`,
                    '--TableRow-stripeBackground': 'rgba(0 0 0 / 0.04)',
                    '--TableRow-hoverBackground': 'rgba(0 0 0 / 0.08)',
                    overflow: 'auto',
                    backgroundColor: 'background.surface',
                })}
            >
                <Table
                    borderAxis="bothBetween"
                    stripe="odd"
                    hoverRow
                    sx={{
                        '& tr > *:first-of-type': {
                            position: 'sticky',
                            left: 0,
                            boxShadow: '1px 0 var(--TableCell-borderColor)',
                            bgcolor: 'background.surface',
                        },
                        '& tr > *:last-child': {
                            position: 'sticky',
                            right: 0,
                            bgcolor: 'var(--TableCell-headBackground)',
                        },
                    }}
                >
                    <thead>
                        <tr>
                            {columns.map((col) => {
                                const active = sortConfig?.key === col.key;
                                const createSortHandler = (key) => 
                                    throttle(() => {
                                        setSortConfig((prev) => ({
                                            key: key,
                                            direction:
                                                prev?.key === key && prev.direction === 'asc'
                                                    ? 'desc'
                                                    : 'asc',
                                        }))
                                    }, throttleDelay);

                                return (
                                    <th
                                        key={col.key}
                                        style={{ width: col.width }}
                                    >
                                        <Link
                                            underline="none"
                                            color="neutral"
                                            textColor={active ? 'primary.plainColor' : undefined}
                                            component="button"
                                            onClick={createSortHandler(col.key)}
                                            endDecorator={
                                                <ArrowDownwardIcon
                                                    sx={{
                                                        opacity: active ? 1 : 0,
                                                        fontSize: '1rem'
                                                    }}
                                                />
                                            }
                                            sx={{
                                                fontWeight: 'lg',
                                                width: '100%',
                                                justifyContent: 'flex-start',
                                                '& svg': {
                                                    transition: '0.2s',
                                                    transform:
                                                        active && sortConfig.direction === 'desc'
                                                            ? 'rotate(0deg)'
                                                            : 'rotate(180deg)',
                                                },
                                                '&:hover': { '& svg': { opacity: 1 } },
                                                position : 'static',
                                            }}
                                        >
                                            {col.label}
                                        </Link>
                                    </th>
                                );
                            })}
                            {actions.length > 0 && (
                                <th style={{ width: 'var(--Table-lastColumnWidth)' }} />
                            )}
                        </tr>
                    </thead>

                    <tbody>
                        {loading ? (
                            Array.from({ length: skeletonRows }).map((_, rowIndex) => (
                                <tr key={rowIndex}>
                                    {columns.map((col) => (
                                        <td key={col.key}>
                                            <Skeleton
                                                variant="text"
                                                level="body-sm"
                                                sx={{ width: '80%' }}
                                            />
                                        </td>
                                    ))}

                                    {actions.length > 0 && (
                                        <td>
                                            <Box sx={{ display: 'flex', gap: 1 }}>
                                                {actions.map((_, i) => (
                                                    <Skeleton
                                                        key={i}
                                                        variant="rectangular"
                                                        width={48}
                                                        height={28}
                                                        sx={{ borderRadius: 'sm' }}
                                                    />
                                                ))}
                                            </Box>
                                        </td>
                                    )}
                                </tr>
                            ))
                        ) : paginatedRows.length === 0 ? (
                            <tr>
                                <td colSpan={columns.length + (actions.length > 0 ? 1 : 0)}>
                                    <Box
                                        sx={{
                                            textAlign: 'center',
                                            py: 6,
                                            color: 'neutral.500',
                                        }}
                                    >
                                        {searchQuery ? 'No results found' : 'No data found'}
                                    </Box>
                                </td>
                            </tr>
                        ) : (
                            paginatedRows.map((row, index) => (
                                <tr key={row.id ?? index}>
                                    {columns.map((col) => (
                                        <td key={col.key}>
                                            {col.render
                                                ? col.render(row[col.key], row)
                                                : row[col.key]}
                                        </td>
                                    ))}

                                    {actions.length > 0 && (
                                        <td>
                                            <Box sx={{ display: 'flex', gap: 1 }}>
                                                {actions.map((action) => (
                                                    <Button
                                                        key={action.label}
                                                        size="sm"
                                                        variant={action.variant ?? 'plain'}
                                                        color={action.color ?? 'neutral'}
                                                        onClick={() => action.onClick(row)}
                                                    >
                                                        {action.label}
                                                    </Button>
                                                ))}
                                            </Box>
                                        </td>
                                    )}
                                </tr>
                            ))
                        )}
                    </tbody>
                </Table>
            </Sheet>

            {/* Pagination */}
            {totalPages > 1 && (
                <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mt: 2 }}>
                    <Typography level="body-sm" sx={{ color: 'neutral.500' }}>
                        Showing {((page - 1) * pageSize) + 1} to {Math.min(page * pageSize, sortedRows.length)} of {sortedRows.length} entries
                    </Typography>
                    <Box sx={{ display: 'flex', gap: 1 }}>
                        <Button
                            size="sm"
                            variant="outlined"
                            disabled={page === 1}
                            onClick={() => setPage((p) => p - 1)}
                        >
                            Prev
                        </Button>
                        <Typography level="body-sm" sx={{ px: 2, py: 1, alignSelf: 'center' }}>
                            Page {page} of {totalPages}
                        </Typography>
                        <Button
                            size="sm"
                            variant="outlined"
                            disabled={page >= totalPages}
                            onClick={() => setPage((p) => p + 1)}
                        >
                            Next
                        </Button>
                    </Box>
                </Box>
            )}
        </Box>
    );
}

export default DataTable;
