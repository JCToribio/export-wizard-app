// Lightweight records table - not used separately in this scaffold but provided as starting point
import React from 'react'

export default function RecordsTable({records, selectedIds, onToggle}){
  return (
    <table className="table table-sm">
      <thead><tr><th></th><th>Name</th><th>Specialty</th><th>City</th><th>State</th></tr></thead>
      <tbody>
        {records.map(r => (
          <tr key={r.id}>
            <td><input type="checkbox" checked={selectedIds.has(r.id)} onChange={()=>onToggle(r.id)} /></td>
            <td>{r.name}</td>
            <td>{r.specialty}</td>
            <td>{r.city}</td>
            <td>{r.state}</td>
          </tr>
        ))}
      </tbody>
    </table>
  )
}
