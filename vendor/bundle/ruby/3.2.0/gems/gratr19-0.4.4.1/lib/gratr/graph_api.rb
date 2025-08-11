#--
# Copyright (c) 2006 Shawn Patrick Garbett
# Copyright (c) 2002,2004,2005 by Horst Duchene
# 
# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:
# 
#     * Redistributions of source code must retain the above copyright notice(s),
#       this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright notice,
#       this list of conditions and the following disclaimer in the documentation
#       and/or other materials provided with the distribution.
#     * Neither the name of the Shawn Garbett nor the names of its contributors
#       may be used to endorse or promote products derived from this software
#       without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE AREf
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#++


module GRATR
  
  # This defines the minimum set of functions required to make a graph class that can
  # use the algorithms defined by this library
  module GraphAPI
    
    # Is the graph directed?
    # 
    # This method must be implemented by the specific graph class
    def directed?()             raise NotImplementedError; end

    # Add a vertex to the Graph and return the Graph
    # An additional label l can be specified as well
    # 
    # This method must be implemented by the specific graph class    
    def add_vertex!(v,l=nil)     raise NotImplementedError; end
      
    # Add an edge to the Graph and return the Graph
    # u can be an object of type GRATR::Arc or u,v specifies
    # a source, target pair. The last parameter is an optional label
    # 
    # This method must be implemented by the specific graph class
    def add_edge!(u,v=nil,l=nil) raise NotImplementedError; end
      
    # Remove a vertex to the Graph and return the Graph
    # 
    # This method must be implemented by the specific graph class
    def remove_vertex!(v)        raise NotImplementedError; end
      
    # Remove an edge from the Graph and return the Graph
    # 
    # Can be a type of GRATR::Arc or a source and target
    # This method must be implemented by the specific graph class
    def remove_edge!(u,v=nil)    raise NotImplementedError; end
            
    # Return the array of vertices.
    # 
    # This method must be implemented by the specific graph class
    def vertices()              raise NotImplementedError; end

    # Return the array of edges.
    # 
    # This method must be implemented by the specific graph class
    def edges()                 raise NotImplementedError; end
      
    # Returns the edge class
    def edge_class()            raise NotImplementedError; end
    
    # Return the chromatic number for this graph
    # This is currently incomplete and in some cases will be NP-complete
    # FIXME: Should this even be here? My gut feeling is no...
    def chromatic_number()      raise NotImplementedError; end
  end
end