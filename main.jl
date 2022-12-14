#Dynamically Triangulated Monte Carlo in Julia 1.8.2
#Packages Meshes,MeshViz,Makie (for plotting), JLD for fileIO
#creation of triangulated sphere from icosahedral inspired by https://github.com/JanisErdmanis/LaplaceBIE.jl/blob/master/examples/sphere.jl
using Meshes, MeshViz
import GLMakie as Mke
using Plots
gr()
include("sphere.jl")
include("MC_sweep.jl")
println("libraries loaded")
ico = create_ico()
sph=subNtimes(3,ico)
sph=normEdges(sph)
L=100
CELLS= genCells(sph,L,L,L, L) #radius of sphere circa =2^k where k is number of subdivision, so create cells a bit bigger
sgq = genGeoQuant(sph)
PartIns=64
part=[-1 for i in 1:sgq.Nv]
part[shuffle(collect(1:sgq.Nv))[1:PartIns]].=+1
sigma=0.08
lmax=sqrt(3)
radius=0.5
k=20
mu=5
Nsvert=sgq.Nv
Nslink=sgq.Nv
Nspart=6
Nsweep=1000

function sweeprun(sgq,CELLS,sigma, lmax, radius, k,part, mu, Nsvert,Nslink,Nspart,N)
	x=[]
	y=[]
	y_ene=[]
	for l in 1:N	
		println("step ", l)
		sgq, part=MC_sweepPM(sgq,CELLS,sigma, lmax, radius, k,part, mu,Nsvert,Nslink,Nspart, verbose=false)
		"""
		mesh=prep4plot(sgq.vertices, sgq.faces)
		fig = Mke.Figure(resolution = (800, 400))
		viz(fig[1,1], mesh, showfacets=true)
		for i in 1:sgq.Nv
			magn=0.3
			if part[i]==+1
				viz!(fig[1,1],Sphere((sgq.vertices[i][1],sgq.vertices[i][2],sgq.vertices[i][3]),radius*magn), color=:red)
			end
		end
		Mke.save("frames/step_"*string(l)*".png",fig)
		fig=Nothing
		"""
		push!(x,l)
		av=[]
		for i in 1:sgq.Nv
			if part[i]==1
				for j in sgq.neig[i]
					if part[j]==1
						push!(av, 1)
						break
					end
				end
			end			
		end
		push!(y, sum(av)/PartIns)
		push!(y_ene, ev_energy(sgq,k,part,mu))
	end
	return x,y,y_ene
end
a,b,c=sweeprun(sgq,CELLS,sigma, lmax, radius, k,part, mu, Nsvert,Nslink,Nspart,Nsweep)
println("plotting")
function plotfunc()
	mesh=prep4plot(sgq.vertices, sgq.faces)
	fig = Mke.Figure(resolution = (800, 400))
	viz(fig[1,1], mesh, showfacets=true)
	for i in 1:sgq.Nv
		magn=0.3
		if part[i]==+1
			viz!(fig[1,1],Sphere((sgq.vertices[i][1],sgq.vertices[i][2],sgq.vertices[i][3]),radius*magn), color=:red)
			"""
			for ed in sgq.neig_edges[i]
				m=sgq.vertices[sgq.edges[ed][1]].+sgq.vertices[sgq.edges[ed][2]]
				m/=2
				viz!(fig[1,1],Sphere((m[1],m[2],m[3]),radius*magn), color=:green)
			end
			"""
		end
	end
	return fig
end
display(plot(a,b))
plotfunc()
