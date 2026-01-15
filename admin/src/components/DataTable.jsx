import React from 'react';
import Box from '@mui/joy/Box';
import Button from '@mui/joy/Button';
import Table from '@mui/joy/Table';
import Sheet from '@mui/joy/Sheet';
import Skeleton from '@mui/joy/Skeleton';

function DataTable({
    columns,
    rows,
    actions = [],
    loading = false,
    skeletonRows = 5,
    firstColumnWidth = 80,
    lastColumnWidth = 144,
}) {

    return (
        <Box sx={{ width: '100%' }}>
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
                            {columns.map((col) => (
                                <th key={col.key} style={{ width: col.width }}>
                                    {col.label}
                                </th>
                            ))}
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
                        ) : rows.length === 0 ? (
                            <tr>
                                <td colSpan={columns.length + (actions.length > 0 ? 1 : 0)}>
                                    <Box
                                        sx={{
                                            textAlign: 'center',
                                            py: 6,
                                            color: 'neutral.500',
                                        }}
                                    >
                                        No sports found
                                    </Box>
                                </td>
                            </tr>
                        ) : (
                            rows.map((row, index) => (
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
        </Box>
    );
}

export default DataTable;
