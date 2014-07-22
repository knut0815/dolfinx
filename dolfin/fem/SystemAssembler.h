// Copyright (C) 2008-2013 Kent-Andre Mardal and Garth N. Wells
//
// This file is part of DOLFIN.
//
// DOLFIN is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// DOLFIN is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with DOLFIN. If not, see <http://www.gnu.org/licenses/>.
//
// Modified by Anders Logg 2008-2011
//
// First added:  2009-06-22
// Last changed: 2013-04-23

#ifndef __SYSTEM_ASSEMBLER_H
#define __SYSTEM_ASSEMBLER_H

#include <array>
#include <map>
#include <memory>
#include <vector>

#include "DirichletBC.h"
#include "AssemblerBase.h"

namespace ufc
{
  class cell;
  class cell_integral;
  class exterior_facet_integral;
}

namespace dolfin
{

  // Forward declarations
  class Cell;
  class Facet;
  class Form;
  class GenericDofMap;
  class GenericMatrix;
  class GenericVector;
  template<typename T> class MeshFunction;
  class UFC;

  /// This class provides an assembler for systems of the form
  /// Ax = b. It differs from the default DOLFIN assembler in that it
  /// applies boundary conditions at the time of assembly, which
  /// preserves any symmetries in A.

  class SystemAssembler : public AssemblerBase
  {
  public:

    /// Constructor
    SystemAssembler(const Form& a, const Form& L);

    /// Constructor
    SystemAssembler(const Form& a, const Form& L, const DirichletBC& bc);

    /// Constructor
    SystemAssembler(const Form& a, const Form& L,
                    const std::vector<const DirichletBC*> bcs);

    /// Constructor
    SystemAssembler(std::shared_ptr<const Form> a,
                    std::shared_ptr<const Form> L);

    /// Constructor
    SystemAssembler(std::shared_ptr<const Form> a,
                    std::shared_ptr<const Form> L,
                    const DirichletBC& bc);

    /// Constructor
    SystemAssembler(std::shared_ptr<const Form> a,
                    std::shared_ptr<const Form> L,
                    const std::vector<const DirichletBC*> bcs);

    /// Assemble system (A, b)
    void assemble(GenericMatrix& A, GenericVector& b);

    /// Assemble matrix A
    void assemble(GenericMatrix& A);

    /// Assemble vector b
    void assemble(GenericVector& b);

    /// Assemble system (A, b) for (negative) increment dx, where
    /// x = x0 - dx is solution to system a == -L subject to bcs.
    /// Suitable for use inside a (quasi-)Newton solver.
    void assemble(GenericMatrix& A, GenericVector& b, const GenericVector& x0);

    /// Assemble rhs vector b for (negative) increment dx, where
    /// x = x0 - dx is solution to system a == -L subject to bcs.
    /// Suitable for use inside a (quasi-)Newton solver.
    void assemble(GenericVector& b, const GenericVector& x0);

  private:

    // Class to hold temporary data
    class Scratch
    {
    public:
      Scratch(const Form& a, const Form& L);
      ~Scratch();
      void zero_cell();
      std::array<std::vector<double>, 2> Ae;
    };

    // Check form arity
    static void check_arity(std::shared_ptr<const Form> a,
                            std::shared_ptr<const Form> L);

    // Assemble system
    void assemble(GenericMatrix* A, GenericVector* b,
                  const GenericVector* x0);

    // Bilinear and linear forms
    std::shared_ptr<const Form> _a, _l;

    // Boundary conditions
    std::vector<const DirichletBC*> _bcs;

    static void
      cell_wise_assembly(std::array<GenericTensor*, 2>& tensors,
                         std::array<UFC*, 2>& ufc,
                         Scratch& data,
                         const DirichletBC::Map& boundary_values,
                         const MeshFunction<std::size_t>* cell_domains,
                       const MeshFunction<std::size_t>* exterior_facet_domains);

    static void
    facet_wise_assembly(std::array<GenericTensor*, 2>& tensors,
                        std::array<UFC*, 2>& ufc,
                        Scratch& data,
                        const DirichletBC::Map& boundary_values,
                        const MeshFunction<std::size_t>* cell_domains,
                        const MeshFunction<std::size_t>* exterior_facet_domains,
                       const MeshFunction<std::size_t>* interior_facet_domains);

    // Compute single facet (and possible connected cell)
    // contribution
    static void assemble_exterior_facet(
      Scratch& data,
      std::array<GenericTensor*, 2>& tensors,
      const Mesh& mesh,
      const Facet& facet,
      const DirichletBC::Map& boundary_values,
      std::array<UFC*, 2>& ufc,
      std::array<ufc::cell, 2>& ufc_cell,
      std::array<std::vector<double>, 2>& vertex_coordinates,
      std::array<std::array<std::vector<const std::vector<dolfin::la_index>* >, 2 >, 2>& cell_dofs,
      const std::array<std::vector<const GenericDofMap*>, 2>& dofmaps,
      std::array<const ufc::cell_integral*, 2>& cell_integrals,
      std::array<const ufc::exterior_facet_integral*, 2>& exterior_facet_integrals,
      const MeshFunction<std::size_t>* cell_domains,
      const MeshFunction<std::size_t>* exterior_facet_domains);

    static void apply_bc(double* A, double* b,
                         const DirichletBC::Map& boundary_values,
                         const std::vector<dolfin::la_index>& global_dofs0,
                         const std::vector<dolfin::la_index>& global_dofs1);

    // Return true if cell has an Dirichlet/essential boundary
    // condition applied
    static bool has_bc(const DirichletBC::Map& boundary_values,
                       const std::vector<dolfin::la_index>& dofs);

    // Return true if element matrix is required
    static bool cell_matrix_required(const GenericTensor* A,
                                     const void* integral,
                                     const DirichletBC::Map& boundary_values,
                                     const std::vector<dolfin::la_index>& dofs);

  };

}

#endif
