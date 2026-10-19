import React, {useState, useEffect, useRef} from 'react'
import api from '../api'

export default function ExportWizard(){
  const [step, setStep] = useState(1)
  const [filters, setFilters] = useState({ contactMethods: ['EMAIL'], categoryIds: [], specialties: [], geo: { mode: 'national' }, cities: [] })
  const [specialtyCounts, setSpecialtyCounts] = useState([])
  const [sampleRows, setSampleRows] = useState([])
  const [pageData, setPageData] = useState({ records: [], page: 1, pageSize: 25, totalCount: 0 })
  const [selectedIds, setSelectedIds] = useState(new Set())

  const previewTimer = useRef(null)
  useEffect(()=>{
    if(previewTimer.current) clearTimeout(previewTimer.current)
    previewTimer.current = setTimeout(()=> fetchPreview(), 300)
    return ()=> clearTimeout(previewTimer.current)
  }, [filters.contactMethods, filters.categoryIds, filters.geo])

  async function fetchPreview(){
    try{
      const res = await api.post('/preview.cfm', filters)
      setSpecialtyCounts(res.data.specialties || [])
      setSampleRows(res.data.sampleRows || [])
    }catch(e){
      console.error('preview error', e)
    }
  }

  function toggleContact(method){
    setFilters(f => {
      const exists = f.contactMethods.includes(method)
      const next = { ...f, contactMethods: exists ? f.contactMethods.filter(m=>m!==method) : [...f.contactMethods, method] }
      return next
    })
  }

  function toggleSpecialty(spec){
    setFilters(f => {
      const exists = f.specialties.includes(spec)
      return { ...f, specialties: exists ? f.specialties.filter(s=>s!==spec) : [...f.specialties, spec] }
    })
  }

  async function fetchPage(page){
    const body = { ...filters, pagination: { page, pageSize: 25 } }
    const res = await api.post('/records.cfm', body)
    setPageData({ records: res.data.records || [], page: res.data.page || page, pageSize: res.data.pageSize || 25, totalCount: res.data.totalCount || 0 })
  }

  function toggleId(id){
    setSelectedIds(prev=>{
      const next = new Set(prev)
      if(next.has(id)) next.delete(id); else next.add(id)
      return next
    })
  }

  function selectAllOnPage(){
    setSelectedIds(prev=>{
      const next = new Set(prev)
      pageData.records.forEach(r => next.add(r.id))
      return next
    })
  }

  function deselectAllOnPage(){
    setSelectedIds(prev=>{
      const next = new Set(prev)
      pageData.records.forEach(r => next.delete(r.id))
      return next
    })
  }

  async function startExport(){
    const body = { filters, selectedRecordIds: Array.from(selectedIds) }
    const res = await api.post('/startExport.cfm', body)
    if(res.data.mode === 'sync'){
      window.location = res.data.fileDownloadUrl
    }else{
      alert('Export started (async). Job ID: ' + res.data.jobId)
    }
  }

  return (
    <div>
      {step === 1 && (
        <div>
          <h4>Contact Method</h4>
          <div className="form-check">
            <input className="form-check-input" type="checkbox" checked={filters.contactMethods.includes('EMAIL')} id="emailCheck" onChange={()=>toggleContact('EMAIL')} />
            <label className="form-check-label" htmlFor="emailCheck">Email</label>
          </div>
          <div className="form-check mb-3">
            <input className="form-check-input" type="checkbox" checked={filters.contactMethods.includes('FAX')} id="faxCheck" onChange={()=>toggleContact('FAX')} />
            <label className="form-check-label" htmlFor="faxCheck">Fax</label>
          </div>
          <button className="btn btn-primary" onClick={()=>setStep(2)}>Next</button>
        </div>
      )}

      {step === 2 && (
        <div>
          <h4>Specialties (preview counts)</h4>
          <table className="table table-sm">
            <thead><tr><th>Specialty</th><th>Count</th><th></th></tr></thead>
            <tbody>
              {specialtyCounts.map(s => (
                <tr key={s.specialty}>
                  <td>{s.specialty}</td>
                  <td>{s.count}</td>
                  <td><input type="checkbox" checked={filters.specialties.includes(s.specialty)} onChange={()=>toggleSpecialty(s.specialty)} /></td>
                </tr>
              ))}
            </tbody>
          </table>
          <button className="btn btn-secondary me-2" onClick={()=>setStep(1)}>Back</button>
          <button className="btn btn-primary" onClick={()=>setStep(3)}>Next</button>
        </div>
      )}

      {step === 3 && (
        <div>
          <h4>Geo Filter</h4>
          <div>
            <div className="form-check">
              <input className="form-check-input" type="radio" name="geoMode" checked={filters.geo.mode==='national'} onChange={()=>setFilters(f=>({...f, geo:{mode:'national'}}))} /> National
            </div>
            <div className="form-check">
              <input className="form-check-input" type="radio" name="geoMode" checked={filters.geo.mode==='zip'} onChange={()=>setFilters(f=>({...f, geo:{mode:'zip', zip:'', radiusMiles:25}}))} /> Zip + Radius
            </div>
          </div>
          {filters.geo.mode === 'zip' && (
            <div className="mt-2">
              <input className="form-control mb-2" placeholder="Zip" value={filters.geo.zip||''} onChange={e=>setFilters(f=>({...f, geo:{...f.geo, zip:e.target.value}}))} />
              <input className="form-control" placeholder="Radius miles" value={filters.geo.radiusMiles||25} onChange={e=>setFilters(f=>({...f, geo:{...f.geo, radiusMiles:parseInt(e.target.value||25)}}))} />
            </div>
          )}
          <div className="mt-3">
            <button className="btn btn-secondary me-2" onClick={()=>setStep(2)}>Back</button>
            <button className="btn btn-primary" onClick={()=>{ setStep(4); fetchPage(1); }}>Next</button>
          </div>
        </div>
      )}

      {step === 4 && (
        <div>
          <h4>Records (page {pageData.page})</h4>
          <div className="mb-2">
            <button className="btn btn-sm btn-outline-primary me-2" onClick={()=>fetchPage(Math.max(1, pageData.page-1))}>Prev</button>
            <button className="btn btn-sm btn-outline-primary me-2" onClick={()=>fetchPage(pageData.page+1)}>Next</button>
            <button className="btn btn-sm btn-outline-secondary me-2" onClick={selectAllOnPage}>Select all on page</button>
            <button className="btn btn-sm btn-outline-secondary" onClick={deselectAllOnPage}>Deselect all on page</button>
          </div>

          <table className="table table-sm">
            <thead><tr><th></th><th>Name</th><th>Specialty</th><th>City</th><th>State</th></tr></thead>
            <tbody>
              {pageData.records.map(r => (
                <tr key={r.id}>
                  <td><input type="checkbox" checked={selectedIds.has(r.id)} onChange={()=>toggleId(r.id)} /></td>
                  <td>{r.name}</td>
                  <td>{r.specialty}</td>
                  <td>{r.city}</td>
                  <td>{r.state}</td>
                </tr>
              ))}
            </tbody>
          </table>

          <div className="mt-2">Selected: {selectedIds.size}</div>
          <div className="mt-3">
            <button className="btn btn-secondary me-2" onClick={()=>setStep(3)}>Back</button>
            <button className="btn btn-success" onClick={startExport}>Export Selected</button>
          </div>
        </div>
      )}

    </div>
  )
}
