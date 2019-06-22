#pragma once
#include <EntitasPP/ISystem.h>
#include <EntitasPP/Group.h>
#include <EntitasPP/Pool.h>
#include <base/fixedptmath.h>

namespace Chestnut {
namespace Ball {

class MoveSystem :
	public EntitasPP::ISystem, public EntitasPP::ISetRefPoolSystem, public EntitasPP::IFixedExecuteSystem
{
public:
	
	int SystemType();

	void SetPool(RefCountedPtr<EntitasPP::Pool> pool);

	void FixedExecute();

protected:
	RefCountedPtr<Chestnut::EntitasPP::Pool> pool;

};

}
}